--------------------------------------------------------------------------------
-- Toast notifier -- Fidget-style notifications using the local Win module
--------------------------------------------------------------------------------
local Win = require 'ui.window'
local Timer = require 'utils.timer'
local NS = vim.api.nvim_create_namespace('ToastNotifierNs')
local ACTIVE = {}

local M = {}

-- Default highlight groups (customizable)
local function default_hl()
    return {
        title = 'Title',
        icon = 'Identifier',
        msg = 'NormalFloat',
        border = 'FloatBorder',
        footer = 'Comment',
    }
end

---@alias ToastNotifyLevel  "error"|"info"|"warn"|"warning"|"debug"|"trace"
---@alias ToastNotifyAnchor "NW"|"NE"|"SW"|"SE"

---@class ToastNotifyFlex
---@field min? number  -- >=1 absolute; (0,1] treated as percentage
---@field max? number  -- >=1 absolute; (0,1] treated as percentage

---@class ToastNotifySize
---@field width?  number|ToastNotifyFlex
---@field height? number|ToastNotifyFlex

---@class ToastNotifyOpts
---@field timeout?      number|false
---@field title?        string
---@field icon?         string
---@field level?        ToastNotifyLevel
---@field ft?           string
---@field id?           string
---@field added?        number
---@field opts?         fun(notif: ToastNotify)
---@field more_format?  string
---@field border?       'rounded'|'single'|'none'
---@field relayout?     boolean
---@field size?         ToastNotifySize
---@field row?          number
---@field col?          number
---@field anchor?       ToastNotifyAnchor

---@class ToastNotifyHL
---@field title  string
---@field icon   string
---@field msg    string
---@field border string
---@field footer string

---@class ToastNotifyCtx
---@field ns   integer
---@field opts table
---@field hl   ToastNotifyHL

---@class ToastNotify
---@field msg    string
---@field title? string
---@field icon?  string
---@field ft?    string
---@field id?    string
---@field added? number
---@field opts?  fun(notif: ToastNotify)

---@alias ToastNotifyRender fun(buf: integer, notif: ToastNotify, ctx: ToastNotifyCtx)

---@class ToastNotifyState
---@field win  table   -- Win instance
---@field buf  integer
---@field timer? Timer

---@param msg  string
---@param opts ToastNotifyOpts
---@return ToastNotify
local function build_notify_info(msg, opts)
    return {
        msg = tostring(msg or ''),
        title = opts.title,
        icon = opts.icon
            or (opts.level and (opts.level == 'error' and ' ' or ' '))
            or '',
        ft = opts.ft,
        id = opts.id,
        added = opts.added or os.time(),
        opts = opts.opts,
    }
end

---@param value number
---@param min   number
---@param max   number
---@param parent number
---@return number
local function dim(value, min, max, parent)
    min = math.floor(min < 1 and (parent * min) or min)
    max = math.floor(max < 1 and (parent * max) or max)
    return math.min(max, math.max(min, value))
end

---@param lines string[]
---@param title_text string
---@param footer_text string
---@return number width
---@return number height
---@return number wanted_height
local function compute_dims(lines, title_text, footer_text)
    local pad = 2 -- left+right padding inside border
    local width = math.max(
        vim.fn.strdisplaywidth(title_text) + pad + 2, -- +2 for border chars
        vim.fn.strdisplaywidth(footer_text) + pad + 2
    )
    for _, line in ipairs(lines) do
        width = math.max(width, vim.fn.strdisplaywidth(line) + pad)
    end
    width = dim(width, 40, 0.4, vim.o.columns)

    local wanted_height = #lines
    local height = dim(wanted_height, 1, 0.6, vim.o.lines)
    return width, height, wanted_height
end

---@param value number|ToastNotifyFlex|nil
---@param current number
---@param parent  number
---@return number
local function resolve_size_value(value, current, parent)
    if type(value) == 'number' then
        if value >= 1 then
            return value
        end
        if value > 0 then
            return math.floor(parent * value)
        end
        return current
    end
    if type(value) == 'table' then
        return dim(current, value.min or 0, value.max or 1, parent)
    end
    return current
end

---@param size   ToastNotifySize|nil
---@param width  number
---@param height number
---@return number
---@return number
local function apply_size_override(size, width, height)
    if type(size) == 'table' then
        width = resolve_size_value(size.width, width, vim.o.columns)
        height = resolve_size_value(size.height, height, vim.o.lines)
    end
    return width, height
end

-- Win helpers

---@param win_obj table  Win instance
---@param hl ToastNotifyHL
local function apply_winhighlight(win_obj, hl)
    win_obj.opts.wo = win_obj.opts.wo or {}
    win_obj.opts.wo.winhighlight = ('Normal:%s,NormalNC:%s,FloatBorder:%s,FloatTitle:%s,FloatFooter:%s'):format(
        hl.msg,
        hl.msg,
        hl.border,
        hl.title,
        hl.footer
    )
end

---@param win_obj table  Win instance
local function apply_conceal(win_obj)
    win_obj.opts.wo = win_obj.opts.wo or {}
    win_obj.opts.wo.conceallevel = 2
    win_obj.opts.wo.concealcursor = 'n'
end

---@param win_obj table          Win instance
---@param state   ToastNotifyState
---@param timeout number|false
local function reset_autoclose(win_obj, state, timeout)
    if state.timer then
        state.timer:close()
        state.timer = nil
    end

    if timeout and timeout ~= 0 and timeout ~= false then
        local t = Timer.new(timeout, function()
            state.timer = nil
            if win_obj:is_valid() then
                pcall(function()
                    win_obj:close()
                end)
            end
        end)
        state.timer = t
        t:start()
    end
end

-- compact: border title + plain message lines
---@param buf    integer
---@param notif  ToastNotify
---@param ctx    ToastNotifyCtx
local function render_compact(buf, notif, ctx)
    local title = vim.trim((notif.icon or '') .. ' ' .. (notif.title or ''))
    if title ~= '' then
        ctx.opts.title = { { ' ' .. title .. ' ', ctx.hl.title } }
        ctx.opts.title_pos = 'center'
    end
    vim.api.nvim_buf_set_lines(
        buf,
        0,
        -1,
        false,
        vim.split(notif.msg or '', '\n', { plain = true })
    )
end

---@param buf    integer
---@param notif  ToastNotify
---@param ctx    ToastNotifyCtx
---@param render ToastNotifyRender|nil
local function render_to_buf(buf, notif, ctx, render)
    if type(notif.opts) == 'function' then
        notif.opts(notif)
    end

    ctx = ctx or {}
    ctx.ns = ctx.ns or NS
    ctx.opts = ctx.opts or {}
    ctx.hl = ctx.hl or default_hl()
    render = render or render_compact

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_clear_namespace(buf, ctx.ns, 0, -1)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    render(buf, notif, ctx)
    vim.bo[buf].modifiable = false
end

---@param msg    string
---@param opts   ToastNotifyOpts|nil
---@param render ToastNotifyRender|nil
---@return table  win  Win instance
function M.notify_like(msg, opts, render)
    opts = opts or {}
    local timeout = opts.timeout ~= nil and opts.timeout or 3000
    local size = opts.size or {}
    local hl = default_hl()

    -- resolve border (default 'rounded', false -> 'none')
    local border
    if opts.border == false then
        border = 'none'
    elseif opts.border == nil or opts.border == true then
        border = 'rounded'
    else
        border = opts.border
    end

    local win_obj, buf, state, reuse
    reuse = false

    if opts.id then
        state = ACTIVE[opts.id]
        if state and state.win and state.win:is_valid() then
            win_obj = state.win
            buf = state.buf
            reuse = true
        else
            ACTIVE[opts.id] = nil
            state = nil
        end
    end

    if not win_obj then
        -- Build a Win with sensible notification defaults; real dims set below.
        win_obj = Win.create({
            relative = 'editor',
            anchor = opts.anchor or 'SE',
            row = opts.row or 0.98,
            col = opts.col or 0.98,
            width = 40,
            height = 3,
            border = border,
            focusable = false,
            focus_on_open = false,
            zindex = 200,
            ft = opts.ft or '',
            wo = { number = false, wrap = false, cursorline = false },
            bo = {},
            noautocmd = true,
        })

        -- Open the window to create the buffer, then immediately close the
        -- native window so we can re-open after computing real dimensions.
        win_obj:open()
        buf = win_obj.buf

        state = { win = win_obj, buf = buf }

        if opts.id then
            ACTIVE[opts.id] = state
        end

        -- Clean up ACTIVE table and timer on close.
        local orig_on_close = win_obj.opts.on_close
        win_obj.opts.on_close = function(w)
            if state.timer then
                state.timer:close()
                state.timer = nil
            end
            if opts.id and ACTIVE[opts.id] == state then
                ACTIVE[opts.id] = nil
            end
            if orig_on_close then
                orig_on_close(w)
            end
        end
    end

    -- render content into buffer
    local info = build_notify_info(msg, opts)

    -- Provide a ctx that references the win's opts table so render_compact can
    -- write title / footer directly onto it before we call win:open().
    local ctx = { opts = win_obj.opts, ns = NS, hl = hl }
    render_to_buf(buf, info, ctx, render)

    -- compute & apply dimensions
    if (not reuse) or opts.relayout == true then
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

        local title_text = ''
        if type(win_obj.opts.title) == 'table' then
            ---@diagnostic disable:param-type-mismatch
            for _, chunk in ipairs(win_obj.opts.title) do
                title_text = title_text .. (chunk[1] or '')
            end
        elseif type(win_obj.opts.title) == 'string' then
            ---@diagnostic disable:cast-local-type
            title_text = win_obj.opts.title
        end

        local footer_text = ''
        if type(win_obj.opts.footer) == 'string' then
            footer_text = win_obj.opts.footer
        end

        local width, height, wanted_height =
            compute_dims(lines, title_text, footer_text)
        width, height = apply_size_override(size, width, height)

        -- optional footer when content is truncated
        if wanted_height > height and border ~= 'none' and opts.more_format then
            win_obj.opts.footer =
                opts.more_format:format(wanted_height - height)
            win_obj.opts.footer_pos = 'right'
        end

        win_obj.opts.width = width
        win_obj.opts.height = height

        if opts.row ~= nil then
            win_obj.opts.row = opts.row
        end
        if opts.col ~= nil then
            win_obj.opts.col = opts.col
        end
        if opts.anchor ~= nil then
            win_obj.opts.anchor = opts.anchor
        end

        win_obj.opts.border = border

        apply_winhighlight(win_obj, hl)
        apply_conceal(win_obj)
    end

    -- (re-)open / reconfigure window
    -- Win:open() is idempotent: if the window already exists it just
    -- reconfigures it; otherwise it creates a new one.
    win_obj:open()

    reset_autoclose(win_obj, state, timeout)

    return win_obj
end

---@class ToastNotifyModule
---@field notify_like fun(msg: string, opts: ToastNotifyOpts|nil, render: ToastNotifyRender|nil): table

---@type ToastNotifyModule
return M

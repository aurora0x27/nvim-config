--------------------------------------------------------------------------------
-- Toast notifier -- fidget-style stacked notifications
--
-- Public API (position / size are intentionally NOT exposed):
--
--   Toast.notify(msg, opts)           → win handle
--   Toast.dismiss(id)
--   Toast.dismiss_all()
--
-- opts (ToastNotifyOpts):
--   timeout?     number|false         ms before auto-close (default 3000)
--   title?       string
--   icon?        string
--   level?       "error"|"warn"|"info"|"debug"|"trace"
--   ft?          string               filetype for syntax highlighting
--   id?          string               dedupe key – replaces existing toast
--   relayout?    boolean              force dimension recalculation on update
--   more_format? string               printf-style footer when lines truncated
--   border?      'rounded'|'single'|'none'|false
--   hl?          ToastNotifyHL        override highlight groups
--------------------------------------------------------------------------------

local Win = require 'ui.window'
local Timer = require 'utils.timer'

local NS = vim.api.nvim_create_namespace('ToastNs')
local M = {}

--------------------------------------------------------------------------------
-- layout constants
--------------------------------------------------------------------------------
local LAYOUT = {
    anchor = 'SE', -- always bottom-right
    margin_right = 1, -- columns from right edge
    margin_bottom = 1, -- lines  from bottom edge
    gap = 1, -- lines between toasts (border counts as 1)
    min_width = 40,
    max_width = 0.45, -- fraction of &columns
    max_height = 0.5, -- fraction of &lines
    zindex_base = 200,
}

--------------------------------------------------------------------------------
-- internal state
--------------------------------------------------------------------------------
-- Ordered list of active toasts; index 1 = bottommost (most recent).
-- Each entry: { id, win, buf, timer, height, border }
---@class ToastEntry
---@field id       string|nil
---@field win      Win          Win instance
---@field buf      integer
---@field timer    table|nil    Timer instance
---@field height   integer      current rendered height (without border)
---@field border   string       'rounded'|'single'|'none'

---@type ToastEntry[]
local STACK = {}

-- id → index in STACK (kept in sync)
---@type table<string, integer>
local ID_MAP = {}

--------------------------------------------------------------------------------
-- highlight defaults
--------------------------------------------------------------------------------
---@class ToastNotifyHL
---@field title  string
---@field icon   string
---@field msg    string
---@field border string
---@field footer string

---@param lvl integer
---@return ToastNotifyHL
local function default_hl(lvl)
    local level_map = {
        [vim.log.levels.ERROR] = {
            icon = 'DiagnosticError',
            title = 'DiagnosticError',
            border = 'DiagnosticError',
        },
        [vim.log.levels.WARN] = {
            icon = 'DiagnosticWarn',
            title = 'DiagnosticWarn',
            border = 'DiagnosticWarn',
        },
        [vim.log.levels.INFO] = {
            icon = 'FloatBorder',
            title = 'FloatBorder',
            border = 'FloatBorder',
        },
        [vim.log.levels.DEBUG] = {
            icon = 'DiagnosticHint',
            title = 'DiagnosticHint',
            border = 'DiagnosticHint',
        },
        [vim.log.levels.TRACE] = {
            icon = 'Comment',
            title = 'Comment',
            border = 'FloatBorder',
        },
    }

    local hl = level_map[lvl] or {}

    return {
        title = hl.title or 'Title',
        icon = hl.icon or 'Identifier',
        msg = 'NormalFloat',
        border = hl.border or 'FloatBorder',
        footer = 'Comment',
    }
end

--------------------------------------------------------------------------------
-- opts type (public, no position/size fields)
--------------------------------------------------------------------------------
---@class ToastNotifyOpts
---@field timeout?      number|false
---@field title?        string
---@field icon?         string
---@field level?        integer
---@field ft?           string
---@field id?           string
---@field mode?         'append'|'replace'
---@field relayout?     boolean
---@field more_format?  string
---@field border?       'rounded'|'single'|'none'|false
---@field hl?           ToastNotifyHL

--------------------------------------------------------------------------------
-- helpers
--------------------------------------------------------------------------------
---@param border string
---@return integer  extra_height  rows consumed by top+bottom border
local function border_h(border)
    return border == 'none' and 0 or 2
end

---@param border string
---@return integer  extra_width  columns consumed by left+right border + padding
local function border_w(border)
    return border == 'none' and 0 or 4 -- 1 border + 1 pad each side
end

---@param opts ToastNotifyOpts
---@return string
local function resolve_border(opts)
    if opts.border == false then
        return 'none'
    elseif opts.border == nil or opts.border == true then
        return 'rounded'
    end
    return opts.border --[[@as string]]
end

---@param opts ToastNotifyOpts
---@return string
local function resolve_icon(opts)
    if opts.icon then
        return opts.icon
    end
    if opts.level then
        local icons = {
            [vim.log.levels.ERROR] = ' ',
            [vim.log.levels.WARN] = ' ',
            [vim.log.levels.INFO] = ' ',
            [vim.log.levels.DEBUG] = '󰃤 ',
            [vim.log.levels.TRACE] = '󰐤 ',
        }
        return icons[opts.level] or ' '
    end
    return ' '
end

--------------------------------------------------------------------------------
-- dimension calculation
--------------------------------------------------------------------------------
---@param lines        string[]
---@param title_text   string
---@param footer_text  string
---@param border       string
---@return integer width
---@return integer height
---@return integer wanted_height
local function compute_dims(lines, title_text, footer_text, border)
    local bw = border_w(border)
    local cols = vim.o.columns
    local rows = vim.o.lines

    local max_w = LAYOUT.max_width >= 1 and LAYOUT.max_width
        or math.floor(cols * LAYOUT.max_width)
    local max_h = LAYOUT.max_height >= 1 and LAYOUT.max_height
        or math.floor(rows * LAYOUT.max_height)

    -- content width needed
    local cw = LAYOUT.min_width - bw
    cw = math.max(cw, vim.fn.strdisplaywidth(title_text))
    cw = math.max(cw, vim.fn.strdisplaywidth(footer_text))
    for _, l in ipairs(lines) do
        cw = math.max(cw, vim.fn.strdisplaywidth(l))
    end

    local width = math.min(max_w, cw + bw)
    local wanted = #lines
    local height = math.min(max_h, math.max(1, wanted))

    return width, height, wanted
end

--------------------------------------------------------------------------------
-- layout engine
--------------------------------------------------------------------------------
-- Returns the col position for SE-anchored windows.
-- nvim_open_win with anchor=SE: col is the RIGHT edge of the window.
local function layout_col()
    return vim.o.columns - LAYOUT.margin_right
end

-- Reflow all toasts after any add / remove / resize.
-- Toasts are stacked upward from the bottom; STACK[1] is bottommost.
local function reflow()
    local bottom = vim.o.lines - LAYOUT.margin_bottom -- SE row anchor
    local cursor = bottom

    for i = 1, #STACK do
        local entry = STACK[i]
        if entry.win:is_valid() then
            local bh = border_h(entry.border)
            local total = entry.height + bh -- full rows this window occupies

            -- SE anchor: row = bottom edge of window
            local row = cursor
            local col = layout_col()

            local new_opts = {
                row = row,
                col = col,
                anchor = LAYOUT.anchor,
            }
            entry.win:update(new_opts) -- lightweight: only set_config pos

            cursor = cursor - total - LAYOUT.gap
        end
    end
end

--------------------------------------------------------------------------------
-- stack management
--------------------------------------------------------------------------------
---@param entry ToastEntry
local function push(entry)
    table.insert(STACK, 1, entry)
    -- rebuild id map
    ID_MAP = {}
    for i, e in ipairs(STACK) do
        if e.id then
            ID_MAP[e.id] = i
        end
    end
    reflow()
end

---@param index integer  1-based index into STACK
local function remove_at(index)
    local entry = STACK[index]
    if entry.timer then
        entry.timer:close()
        entry.timer = nil
    end
    table.remove(STACK, index)
    -- rebuild id map
    ID_MAP = {}
    for i, e in ipairs(STACK) do
        if e.id then
            ID_MAP[e.id] = i
        end
    end
    reflow()
end

--------------------------------------------------------------------------------
-- autoclose timer
--------------------------------------------------------------------------------
---@param entry   ToastEntry
---@param timeout number|false
local function arm_timer(entry, timeout)
    if entry.timer then
        entry.timer:close()
        entry.timer = nil
    end
    if not timeout or timeout == false or timeout == 0 then
        return
    end

    local t = Timer.new(timeout, function()
        entry.timer = nil
        -- find and close
        for i, e in ipairs(STACK) do
            if e == entry then
                if e.win:is_valid() then
                    pcall(function()
                        e.win:close()
                    end)
                else
                    remove_at(i)
                end
                break
            end
        end
    end)
    entry.timer = t
    t:start()
end

--------------------------------------------------------------------------------
-- rendering
--------------------------------------------------------------------------------
---@param buf       integer
---@param notif_msg string
---@param title     string
---@param icon      string
---@param win_opts  table   Win.opts (mutated for title/footer)
---@param hl        ToastNotifyHL
---@param ns        integer
local function render_into(buf, notif_msg, title, icon, win_opts, hl, ns)
    -- title bar in window border
    local title_chunks = {
        { ' ', hl.title },
        { icon or ' ', hl.icon },
        { ' ', hl.title },
        { title or ' Messages ', hl.title },
        { ' ', hl.title },
    }

    win_opts.title = title_chunks
    win_opts.title_pos = 'center'

    -- apply winhighlight
    win_opts.wo = win_opts.wo or {}
    win_opts.wo.winhighlight = ('Normal:%s,NormalNC:%s,FloatBorder:%s,FloatTitle:%s,FloatFooter:%s'):format(
        hl.msg,
        hl.msg,
        hl.border,
        hl.title,
        hl.footer
    )
    win_opts.wo.conceallevel = 2
    win_opts.wo.concealcursor = 'n'

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    vim.api.nvim_buf_set_lines(
        buf,
        0,
        -1,
        false,
        vim.split(notif_msg or '', '\n', { plain = true })
    )
    vim.bo[buf].modifiable = false
end

--------------------------------------------------------------------------------
-- public API
--------------------------------------------------------------------------------
---Show (or update) a toast notification.
---@param msg  string
---@param opts ToastNotifyOpts|nil
---@return table  win  Win instance
function M.notify(msg, opts)
    opts = opts or {}
    local timeout = opts.timeout ~= nil and opts.timeout or 3000
    local border = resolve_border(opts)
    local mode = opts.mode or 'replace'
    local hl = vim.tbl_extend('force', default_hl(opts.level), opts.hl or {})
    local icon = resolve_icon(opts)
    local title = opts.title or ' Messages '

    -- reuse existing toast for same id
    local existing_idx = opts.id and ID_MAP[opts.id]
    local entry ---@type ToastEntry|nil

    if existing_idx then
        entry = STACK[existing_idx]
        if not entry.win:is_valid() then
            remove_at(existing_idx)
            entry = nil
        end
    end

    if entry then
        local final_msg = msg

        if mode == 'append' and entry.win:is_valid() then
            local old_lines =
                vim.api.nvim_buf_get_lines(entry.buf, 0, -1, false)
            local old_msg = table.concat(old_lines, '\n')
            final_msg = old_msg .. '\n' .. msg
        end

        -- update in place
        render_into(entry.buf, final_msg, title, icon, entry.win.opts, hl, NS)

        if opts.relayout ~= false then
            -- recompute dimensions
            local lines = vim.api.nvim_buf_get_lines(entry.buf, 0, -1, false)
            local title_text = title ~= '' and (icon .. ' ' .. title) or ''
            local footer_text = type(entry.win.opts.footer) == 'string'
                    and entry.win.opts.footer
                or '' --[[@as string]]
            local w, h, wanted =
                compute_dims(lines, title_text, footer_text, border)

            if wanted > h and border ~= 'none' and opts.more_format then
                entry.win.opts.footer = opts.more_format:format(wanted - h)
                entry.win.opts.footer_pos = 'right'
            else
                entry.win.opts.footer = nil
            end

            entry.win.opts.width = w
            entry.height = h
            entry.win.opts.height = h
        end

        entry.win:open() -- reconfigure (idempotent)
        arm_timer(entry, timeout)
        reflow()
        return entry.win
    end

    -- create new toast
    -- Placeholder position; reflow() corrects it immediately after push().
    local placeholder_row = vim.o.lines - LAYOUT.margin_bottom
    local placeholder_col = layout_col()

    local win_obj = Win.create({
        relative = 'editor',
        anchor = LAYOUT.anchor,
        row = placeholder_row,
        col = placeholder_col,
        width = LAYOUT.min_width,
        height = 3,
        border = border,
        focusable = false,
        focus_on_open = false,
        zindex = LAYOUT.zindex_base,
        ft = opts.ft or '',
        wo = { number = false, wrap = false, cursorline = false },
        bo = {},
        noautocmd = true,
    })

    win_obj:open()
    local buf = win_obj.buf

    render_into(buf, msg, title, icon, win_obj.opts, hl, NS)

    -- compute real dimensions
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local title_text = title ~= '' and (icon .. ' ' .. title) or ''
    local w, h, wanted = compute_dims(lines, title_text, '', border)

    if wanted > h and border ~= 'none' and opts.more_format then
        win_obj.opts.footer = opts.more_format:format(wanted - h)
        win_obj.opts.footer_pos = 'right'
    end

    win_obj.opts.width = w
    win_obj.opts.height = h
    win_obj:open() -- reconfigure with real dims

    ---@type ToastEntry
    local new_entry = {
        id = opts.id,
        win = win_obj,
        buf = buf,
        timer = nil,
        height = h,
        border = border,
    }

    -- wire up cleanup on window close (user presses q, etc.)
    local orig_on_close = win_obj.opts.on_close
    win_obj.opts.on_close = function(win)
        for i, e in ipairs(STACK) do
            if e == new_entry then
                remove_at(i)
                break
            end
        end
        if orig_on_close then
            orig_on_close(win)
        end
    end

    arm_timer(new_entry, timeout)
    push(new_entry) -- inserts at bottom and reflowing

    return win_obj
end

---Dismiss a specific toast by id.
---@param id string
function M.dismiss(id)
    local idx = ID_MAP[id]
    if not idx then
        return
    end
    local entry = STACK[idx]
    if entry.win:is_valid() then
        pcall(function()
            entry.win:close()
        end)
    else
        remove_at(idx)
    end
end

---Dismiss all active toasts.
function M.dismiss_all()
    -- iterate in reverse so indices remain valid while closing
    for i = #STACK, 1, -1 do
        local entry = STACK[i]
        if entry.win:is_valid() then
            pcall(function()
                entry.win:close()
            end)
        end
    end
    -- on_close callbacks will drain STACK via remove_at
end

-- Re-layout on VimResized (single global autocmd).
vim.api.nvim_create_autocmd('VimResized', {
    group = vim.api.nvim_create_augroup('ToastLayout', { clear = true }),
    callback = reflow,
})

return M

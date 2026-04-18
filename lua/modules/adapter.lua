--------------------------------------------------------------------------------
-- UI Event Adapter: hijack nvim ui-event system and send messages to bus
--------------------------------------------------------------------------------
local M = {}
local bind = require 'utils.loader'.bind
local thunk = require 'utils.loader'.thunk

---@class ExtHandlerDecl for use config
---@field event string
---@field callback fun(event: string, ...): any

---@class AdapterOpt
---@field enable_ui2? boolean
---@field bus_init? BusInitOpt
---@field customed_handlers? ExtHandlerDecl[]

---@class AdapterStat
---@field IsConfirm boolean is in confirm mode

---@class NvimMsgShowData   metadata for msg.show.* messages
---@field kind         string        nvim message kind
---@field offsets      integer[]     start index of each logical msg in content array
---@field replace_last boolean
---@field history      boolean
---@field append       boolean
---@field trigger      string
---@field batched      boolean?      true if merged by batch_emit

---@alias NvimMsgTuple  {[1]: integer, [2]: string, [3]: integer}  single highlight chunk from nvim ui protocol

---@class NvimMsgChunk
---@field attr_id  integer
---@field text     string
---@field hl_id    integer

-- Batch state: accumulate msgs of same kind within a short window
---@class MsgBatch
---@field kind     string
---@field level    vim.log.levels
---@field content  table[]
---@field offsets  integer[]
---@field id       integer|string|nil  nvim msg id of first msg in batch (for cover)
---@field timer    uv.uv_timer_t
---@field flushing boolean

---@class AdapterOpt
local ADAPTER_OPT_DEFAULT = {
    enable_ui2 = false,
    bus_init = {},
}

---@type AdapterOpt
local Opt = vim.deepcopy(ADAPTER_OPT_DEFAULT)

---@type AdapterStat
local Stat = {
    IsConfirm = false,
}

local Handlers = {}

Handlers.on_cmdline_show = thunk('modules.popup', 'on_cmdline_show')
Handlers.on_cmdline_pos = thunk('modules.popup', 'on_cmdline_pos')
Handlers.on_cmdline_hide = thunk('modules.popup', 'on_cmdline_hide')

local ConfirmHandlers = {}

local ConfirmData = nil

---@type table<string, MsgBatch>  kind -> batch
local MsgBatches = {}

local BATCH_KINDS = {
    echo = true,
    echomsg = true,
    lua_print = true,
    progress = true, -- :Notification uses nvim_echo -> progress kind
}

local BATCH_DELAY_MS = 20 -- flush after 20ms idle

--- Emit a message to bus, Wrapper function
--- if in confirm mode, handle it carefully, use sync mode
--- in normal cases just schedule it to next loop, do not block
---@param tag string
---@param level integer
---@param content string|table
---@param data? table
---@param cover_id? integer
local function emit_wrap(tag, level, content, data, cover_id)
    if Stat.IsConfirm then
        Bus.emit(tag, level, content, data, cover_id)
    else
        vim.schedule(bind(Bus.emit, tag, level, content, data, cover_id))
    end
end

---@param kind string
local function flush_batch(kind)
    local b = MsgBatches[kind]
    -- guard: already flushed by a concurrent callback
    if not b or b.flushing then
        return
    end
    b.flushing = true
    MsgBatches[kind] = nil

    ---@type NvimMsgShowData
    local data = {
        kind = kind,
        offsets = b.offsets,
        replace_last = false,
        history = false,
        append = false,
        trigger = '',
        batched = true,
    }

    emit_wrap('msg.show.' .. kind, b.level, b.content, data, nil)
end

---@type NvimMsgTuple
local NEWLINE_TUPLE = { 0, '\n', 0 }

---@param kind string
---@param level vim.log.levels
---@param content table
---@param id integer|string|nil
local function batch_emit(kind, level, content, id)
    local b = MsgBatches[kind]
    if b then
        -- stop old timer and close it before creating new one
        b.timer:stop()
        table.insert(b.content, NEWLINE_TUPLE)
        table.insert(b.offsets, #b.content + 1)
        vim.list_extend(b.content, content)
        -- reuse batch, create fresh timer
    else
        b = {
            kind = kind,
            level = level,
            content = content,
            offsets = { 1 },
            id = id,
            timer = assert(vim.uv.new_timer()),
            flushing = false,
        }
        MsgBatches[kind] = b
    end
    b.timer:start(
        BATCH_DELAY_MS,
        0,
        vim.schedule_wrap(function()
            -- close timer inside callback, after it has fired
            if not b.timer:is_closing() then
                b.timer:close()
            end
            flush_batch(kind)
        end)
    )
end

function Handlers.on_msg_show(
    kind,
    content,
    replace_last,
    history,
    append,
    id,
    trigger
)
    if kind == 'confirm' then
        -- TODO: record message and
        Stat.IsConfirm = true
        ConfirmData = {
            kind = kind,
            content = content,
            replace_last = replace_last,
            history = history,
            append = append,
            id = id,
            trigger = trigger,
        }
        return false
    end

    local kind_to_level = {
        emsg = vim.log.levels.ERROR,
        lua_error = vim.log.levels.ERROR,
        rpc_error = vim.log.levels.ERROR,
        echoerr = vim.log.levels.ERROR,
        wmsg = vim.log.levels.WARN,
        echo = vim.log.levels.INFO,
        echomsg = vim.log.levels.INFO,
        lua_print = vim.log.levels.INFO,
        progress = vim.log.levels.INFO,
        verbose = vim.log.levels.DEBUG,
    }
    local level = kind_to_level[kind] or vim.log.levels.INFO
    local tag = 'msg.show.' .. (kind ~= '' and kind or 'unknown')

    -- batch-able kinds: debounce and merge within window
    if BATCH_KINDS[kind] then
        -- only batch non-empty, non-replace messages
        -- replace_last=true means nvim wants to update a specific msg → emit directly
        if not replace_last and #content > 0 then
            batch_emit(kind, level, content, id)
            return
        end
    end

    emit_wrap(tag, level, content, {
        kind = kind,
        offsets = { 1 },
        replace_last = replace_last,
        history = history,
        append = append,
        trigger = trigger,
    }, replace_last and id or nil)
end

function Handlers.on_msg_clear()
    -- Notify subscribers so renderers can wipe their display
    Bus.emit('msg.clear', vim.log.levels.INFO, '', {})
end

---@type uv.uv_timer_t|nil
local on_close_timer = nil

function ConfirmHandlers.on_cmdline_show(...)
    if on_close_timer then
        on_close_timer:stop()
    end
    if ConfirmData then
        bind(thunk('modules.confirm', 'on_cmdline_show'), ConfirmData, ...)()
    end
end

function ConfirmHandlers.on_cmdline_hide(level, abort)
    if on_close_timer then
        -- cleanup old timer
        on_close_timer:stop()
        if not on_close_timer:is_closing() then
            on_close_timer:close()
        end
        on_close_timer = nil
    end

    local function actual_abort()
        bind(thunk('modules.confirm', 'on_cmdline_hide'), level, abort)()
        Stat.IsConfirm = false
        ConfirmData = nil
    end

    if abort then
        actual_abort()
        return
    end

    on_close_timer = assert(vim.uv.new_timer())
    on_close_timer:start(
        50,
        0,
        vim.schedule_wrap(function()
            actual_abort()
        end)
    )
end

local function force_cleanup_confirm()
    if not Stat.IsConfirm then
        return
    end
    bind(thunk('modules.confirm', 'on_cmdline_hide'), 0, true)()
    Stat.IsConfirm = false
    ConfirmData = nil
end

--- Pipe notify message to bus
---@param msg string
---@param lvl integer|nil
---@param opts? table
local function notify_impl(msg, lvl, opts)
    assert(
        type(msg) == 'string'
            and (not lvl or type(lvl) == 'number')
            and (not opts or type(opts) == 'table')
    )
    opts = opts or {}
    if not opts.title then
        opts.title = 'Notify'
    end
    Bus.emit('notify', lvl or vim.log.levels.INFO, msg, opts)
end

---@param opts? AdapterOpt
function M.setup(opts)
    Opt = vim.tbl_deep_extend('force', Opt, opts or {})
    if not Bus then
        -- initialize the bus if not initialized
        require 'modules.bus'.init(Opt.bus_init)
    end
    if Opt.enable_ui2 then
        local ui2 = require 'vim._core.ui2'
        for name, handler in pairs(Handlers) do
            if vim.startswith(name, 'on_') then
                local cover = name:sub(4)
                if ui2[cover] then
                    ui2[cover] = handler
                end
            end
        end
    else
        local ns = vim.api.nvim_create_namespace 'UIEventAdapter'
        vim.ui_attach(
            ns,
            { ext_messages = true, ext_cmdline = true },
            function(event, ...)
                -- identify messages and dispatch to handlers
                local is_cmdline_event = vim.startswith(event, 'cmdline_')

                if Stat.IsConfirm and not is_cmdline_event then
                    local args = { ... }
                    if not (event == 'msg_show' and args[1] == 'confirm') then
                        force_cleanup_confirm()
                    end
                end

                if Stat.IsConfirm and is_cmdline_event then
                    local handler = ConfirmHandlers['on_' .. event]
                    if type(handler) == 'function' then
                        handler(...)
                    end
                    return false
                end

                local handler = Handlers['on_' .. event]
                if type(handler) == 'function' then
                    handler(...)
                end
                return true
            end
        )
    end
    vim.notify = notify_impl
end

return M

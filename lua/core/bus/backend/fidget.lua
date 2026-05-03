--------------------------------------------------------------------------------
-- Toast notifier backend (fidget like)
--------------------------------------------------------------------------------
local thunk = require 'utils.loader'.thunk
local notify = thunk('core.ui.toast', 'notify')
local M = {}

local TITLE_OF_LEVEL = {
    [vim.log.levels.TRACE] = 'Trace',
    [vim.log.levels.DEBUG] = 'Debug',
    [vim.log.levels.INFO] = 'Info',
    [vim.log.levels.WARN] = 'Warn',
    [vim.log.levels.ERROR] = 'Error',
}

---@param msg Message
---@return string
local function get_title(msg)
    return TITLE_OF_LEVEL[msg.level]
end

local MODE_OF_TAG = {
    ['msg.show.bufwrite'] = 'append',
    ['msg.show.lua_print'] = 'append',
    ['msg.show.echo'] = 'append',
    ['msg.show.wmsg'] = 'append',
    ['msg.show.echomsg'] = 'replace',
    ['msg.show.undo'] = 'replace',
    ['msg.show.list_cmd'] = 'replace',
}

---@param msg Message
---@return 'append'|'replace'
local function get_mode(msg)
    return MODE_OF_TAG[msg.tag] or 'replace'
end

---@param msg Message
local function handler(msg)
    local is_system_msg = vim.startswith(msg.tag, 'msg.show.')

    ---@type ToastNotifyOpts
    local opts = {
        id = msg.tag,
        title = is_system_msg and 'Messages' or get_title(msg),
        mode = get_mode(msg),
        level = msg.level,
    }

    notify(msg.content, opts)
end

function M.setup()
    Bus.register_subscriber('fidget', {
        exact = {
            'msg.show.wmsg',
            'msg.show.undo',
            'msg.show.echo',
            'msg.show.echomsg',
            'msg.show.unknown',
            'msg.show.bufwrite',
            'msg.show.progress',
            'msg.show.list_cmd',
            'msg.show.lua_print',
        },
    }, vim.log.levels.TRACE, handler)
end

return M

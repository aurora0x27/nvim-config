local thunk = require 'utils.loader'.thunk
local notify = thunk('ui.toast', 'notify')
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
    ['msg.show.undo'] = 'replace',
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
            'msg.show.undo',
            'msg.show.bufwrite',
            'msg.show.progress',
            'msg.show.unknown',
        },
    }, vim.log.levels.TRACE, handler)
end

return M

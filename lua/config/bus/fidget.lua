local thunk = require 'utils.loader'.thunk
local notify = thunk('ui.toast', 'notify')
local chunk_layout = require 'utils.render'.layout_chunks
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

---@param msg Message
local function handler(msg)
    local is_system_msg = vim.startswith(msg.tag, 'msg.show.')

    local text
    if is_system_msg then
        text = table.concat(chunk_layout(msg.content).lines, '\n')
    else
        text = msg.content
    end

    ---@type ToastNotifyOpts
    local opts = {
        id = msg.tag,
        title = is_system_msg and 'Messages' or get_title(msg),
        level = msg.level,
    }

    notify(text, opts)
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

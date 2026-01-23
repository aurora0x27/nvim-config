local M = {}

local has_yazi = require('utils.detect').is_executable 'yazi'
local tools = require 'utils.tools'

---@module 'toggleterm'
local Terminal = require('toggleterm.terminal').Terminal
local yazi = Terminal:new {
    cmd = 'yazi',
    hidden = true,
}

function M.toggle()
    if has_yazi then
        yazi:toggle()
    else
        tools.err 'Executable `yazi` must be installed to enable file browser'
    end
end

return M

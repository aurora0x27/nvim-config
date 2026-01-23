local M = {}

local has_lazygit = require('utils.detect').is_executable 'yazi'
local tools = require 'utils.tools'

---@module 'toggleterm'
local Terminal = require('toggleterm.terminal').Terminal
local lazygit = Terminal:new {
    cmd = 'lazygit',
    hidden = true,
}

function M.toggle()
    if has_lazygit then
        lazygit:toggle()
    else
        tools.err 'Executable `lazygit` must be installed to enable file browser'
    end
end

return M

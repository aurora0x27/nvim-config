--------------------------------------------------------------------------------
-- Statusline
--------------------------------------------------------------------------------

---@type LazyPluginSpec
local Heirline = {
    'rebelot/heirline.nvim',
    event = 'UIEnter',
    config = function()
        ---@module 'heirline'
        require('heirline').setup {
            statusline = require 'core.ui.heirline.statusline',
            opts = { colors = require 'core.ui.heirline.common.colors' },
        }

        -- set global status line
        vim.o.laststatus = 3
    end,
}

return Heirline

--------------------------------------------------------------------------------
-- Statusline
--------------------------------------------------------------------------------

---@type LazyPluginSpec
local Heirline = {
    'rebelot/heirline.nvim',
    event = 'VeryLazy',
    config = function()
        ---@module 'heirline'
        require('heirline').setup {
            statusline = require 'config.heirline.statusline',
            opts = { colors = require 'config.heirline.common.colors' },
        }

        -- set global status line
        vim.o.laststatus = 3
    end,
}

return Heirline

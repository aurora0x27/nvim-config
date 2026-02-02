-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

---@type LazyPluginSpec
local Heirline = {
    'rebelot/heirline.nvim',
    event = 'VeryLazy',
    ---@module 'heirline'
    config = function()
        require('heirline').setup {
            statusline = require 'config.heirline.statusline',
            opts = { colors = require 'config.heirline.common.colors' },
        }

        -- set global status line
        vim.o.laststatus = 3
    end,
}

return Heirline

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local Heirline = {
    'rebelot/heirline.nvim',
    event = 'VeryLazy',
    config = function()
        local StatusLine = require 'config.heirline.statusline'
        local Colors = require 'config.heirline.common.colors'

        require('heirline').setup {
            statusline = StatusLine,
            opts = { colors = Colors },
        }

        -- set global status line
        vim.o.laststatus = 3
    end,
}

return Heirline

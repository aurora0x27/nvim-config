--------------------------------------------------------------------------------
-- Dropbar, annotions the scope for current cursor pos context
--------------------------------------------------------------------------------

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

---@type LazyPluginSpec
local Outline = {
    'Bekaboo/dropbar.nvim',
    -- optional, but required for fuzzy finder support
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
        local dropbar_api = require 'dropbar.api'
        vim.keymap.set(
            'n',
            '<leader>;',
            dropbar_api.pick,
            { desc = 'Pick Symbols In Dropbar' }
        )
    end,
}

return Outline

-- Outline

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

---@type LazyPluginSpec
local Outline = {
    'Bekaboo/dropbar.nvim',
    -- optional, but required for fuzzy finder support
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
    },
    config = function()
        local dropbar_api = require 'dropbar.api'
        vim.keymap.set('n', '<Leader>;', dropbar_api.pick, { desc = 'Pick Symbols In Dropbar' })
        vim.keymap.set('n', '[;', dropbar_api.goto_context_start, { desc = 'Go To Start Of Current Context' })
        vim.keymap.set('n', '];', dropbar_api.select_next_context, { desc = 'Select Next Context' })
    end,
}

return Outline

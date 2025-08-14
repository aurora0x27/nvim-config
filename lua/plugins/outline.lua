-- Outline

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

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
        vim.keymap.set('n', '<Leader>;', dropbar_api.pick, { desc = 'Pick symbols in dropbar' })
        vim.keymap.set('n', '[;', dropbar_api.goto_context_start, { desc = 'Go to start of current context' })
        vim.keymap.set('n', '];', dropbar_api.select_next_context, { desc = 'Select next context' })
    end,
}

return Outline

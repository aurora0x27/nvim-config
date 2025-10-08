-- Indent line

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local IndentLine = {
    'lukas-reineke/indent-blankline.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    main = 'ibl',

    config = function()
        local mocha = require('catppuccin.palettes').get_palette 'mocha'
        local hooks = require 'ibl.hooks'
        -- create the highlight groups in the highlight setup hook, so they are reset
        -- every time the colorscheme changes
        hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
            vim.api.nvim_set_hl(0, 'IndentLineNotSelected', { fg = mocha.overlay0 })
            vim.api.nvim_set_hl(0, 'IndentLineSelected', { fg = mocha.teal })
        end)

        hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)

        require('ibl').setup {
            indent = { highlight = {
                'IndentLineNotSelected',
            }, char = '│' },
            scope = {
                highlight = {
                    'IndentLineSelected',
                },
                enabled = true,
                show_start = false,
                show_end = false,
            },
        }
    end,
}

return IndentLine

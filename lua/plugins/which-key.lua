-- Useful plugin to show you pending keybinds.

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local KeyMapIntellisense = {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
        preset = 'helix',

        icons = {
            breadcrumb = '', -- symbol used in the command line area that shows your active key combo
            separator = '→', -- symbol used between a key and it's label
            group = ' ', -- symbol prepended to a group
            -- set icon mappings to true if you have a Nerd Font
            mappings = false,
            -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
            -- default which-key.nvim defined Nerd Font icons, otherwise define a string table
            keys = vim.g.have_nerd_font and {} or {
                Up = '<Up> ',
                Down = '<Down> ',
                Left = '<Left> ',
                Right = '<Right> ',
                C = '<C-…> ',
                M = '<M-…> ',
                D = '<D-…> ',
                S = '<S-…> ',
                CR = '<CR> ',
                Esc = '<Esc> ',
                ScrollWheelDown = '<ScrollWheelDown> ',
                ScrollWheelUp = '<ScrollWheelUp> ',
                NL = '<NL> ',
                BS = '<BS> ',
                Space = '<Space> ',
                Tab = '<Tab> ',
                F1 = '<F1>',
                F2 = '<F2>',
                F3 = '<F3>',
                F4 = '<F4>',
                F5 = '<F5>',
                F6 = '<F6>',
                F7 = '<F7>',
                F8 = '<F8>',
                F9 = '<F9>',
                F10 = '<F10>',
                F11 = '<F11>',
                F12 = '<F12>',
            },
        },

        -- Document existing key chains
        spec = {
            { '<leader>f', group = '[F]ind' },
            { '<leader>e', group = '[E]xplorer' },
            { '<leader>l', group = '[L]anguage Utils' },
            { '<leader>t', group = '[T]ab' },
            { '<leader>p', group = '[P]review' },
            { '<leader>b', group = '[B]uffer' },
            { '<leader>r', group = '[R]un tasks' },
            { '<leader>g', group = '[G]it', mode = { 'n', 'v' } },
            { '<leader>gh', group = 'Git [H]unk', mode = { 'n', 'v' } },
            { '<leader>gt', group = 'Git [T]oggle', mode = { 'n', 'v' } },
        },
    },
}

return KeyMapIntellisense

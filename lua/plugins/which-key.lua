-- Useful plugin to show you pending keybinds.

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local KeyMapIntellisense = {
    'folke/which-key.nvim',
    event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    opts = {
        preset = 'helix',
        icons = {
            -- set icon mappings to true if you have a Nerd Font
            mappings = vim.g.have_nerd_font,
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
            -- { '<leader>c', group = '[C]ode', mode = { 'n', 'x' } },
            -- { '<leader>d', group = '[D]ocument' },
            -- { '<leader>r', group = '[R]ename' },
            { '<leader>f', group = '[F]ind' },
            { '<leader>e', group = '[E]xplorer' },
            { '<leader>l', group = '[L]anguageUtils' },
            { '<leader>p', group = '[P]review' },
            { '<leader>b', group = '[B]uffer' },
            { '<leader>g', group = '[G]it', mode = { 'n', 'v' } },
        },
    },
}

return KeyMapIntellisense

--------------------------------------------------------------------------------
-- Float window terminal
--------------------------------------------------------------------------------

local thunk = require('utils.loader').thunk
local mocha = require('catppuccin.palettes').get_palette 'mocha'

---@type LazyPluginSpec
local IntergratedTerminal = {
    'akinsho/toggleterm.nvim',
    -- event = 'VeryLazy',
    lazy = true,
    version = '*',
    ---@module 'toggleterm'
    ---@type ToggleTermConfig|{}
    opts = {
        open_mapping = { '<c-\\>', '<F7>' },
        shade_filetypes = {},
        autochdir = false,

        highlights = {
            FloatBorder = {
                guifg = mocha.blue,
            },
        },

        start_in_insert = true,
        insert_mappings = true, -- whether or not the open mapping applies in insert mode
        terminal_mappings = true, -- whether or not the open mapping applies in the opened terminals
        persist_size = true,
        persist_mode = true, -- if set to true (default) the previous terminal mode will be remembered
        direction = 'float',
        close_on_exit = true, -- close the terminal window when the process exits
        clear_env = false, -- use only environmental variables from `env`, passed to jobstart()
        -- Change the default shell. Can be a string or a function returning a string
        shell = vim.o.shell,
        auto_scroll = true, -- automatically scroll to the bottom on terminal output
        float_opts = {
            border = 'rounded', -- other options supported by win open
            -- like `size`, width, height, row, and col can be a number or function which is passed the current terminal
            -- width = <value>,
            -- height = <value>,
            -- row = <value>,
            -- col = <value>,
            -- winblend = 3,
            -- zindex = <value>,
            -- title_pos = 'left' | 'center' | 'right', position of the title of the floating window
        },
        winbar = {
            enabled = false,
            name_formatter = function(term) --  term: Terminal
                return term.name
            end,
        },
        responsiveness = {
            horizontal_breakpoint = 135,
        },
    },
    keys = {
        { '<Leader>ts', '<cmd>TermSelect<cr>', desc = '[T]erm [S]elect' },
        { '<C-\\>', thunk('toggleterm', 'toggle'), desc = 'Toggle Terminal' },
    },
}

return IntergratedTerminal

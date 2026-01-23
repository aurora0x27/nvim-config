local WinBorder = require('utils.assets').border

local FzfLua = {
    'ibhagwan/fzf-lua',
    -- optional for icon support
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    lazy = true,
    cmd = { 'FzfLua' },
    ---@module "fzf-lua"
    ---@type fzf-lua.Config|{}
    opts = {
        keymap = {
            -- Below are the default binds, setting any value in these tables will override
            -- the defaults, to inherit from the defaults change [1] from `false` to `true`
            builtin = {
                -- neovim `:tmap` mappings for the fzf win
                -- true,        -- uncomment to inherit all the below in your custom config
                ['<M-Esc>'] = 'hide', -- hide fzf-lua, `:FzfLua resume` to continue
                ['<F1>'] = 'toggle-help',
                ['<F2>'] = 'toggle-fullscreen',
                -- Only valid with the 'builtin' previewer
                ['<F3>'] = 'toggle-preview-wrap',
                ['<F4>'] = 'toggle-preview',
                -- Rotate preview clockwise/counter-clockwise
                ['<F5>'] = 'toggle-preview-cw',
                -- Preview toggle behavior default/extend
                ['<F6>'] = 'toggle-preview-behavior',
                -- `ts-ctx` binds require `nvim-treesitter-context`
                ['<F7>'] = 'toggle-preview-ts-ctx',
                ['<F8>'] = 'preview-ts-ctx-dec',
                ['<F9>'] = 'preview-ts-ctx-inc',
                ['<S-Left>'] = 'preview-reset',
                ['<S-down>'] = 'preview-page-down',
                ['<S-up>'] = 'preview-page-up',
                ['<M-S-down>'] = 'preview-down',
                ['<M-S-up>'] = 'preview-up',
            },
            fzf = {
                -- fzf '--bind=' options
                -- true,        -- uncomment to inherit all the below in your custom config
                ['ctrl-z'] = 'abort',
                ['ctrl-u'] = 'unix-line-discard',
                ['ctrl-f'] = 'half-page-down',
                ['ctrl-b'] = 'half-page-up',
                ['ctrl-a'] = 'beginning-of-line',
                ['ctrl-e'] = 'end-of-line',
                ['alt-a'] = 'toggle-all',
                ['alt-g'] = 'first',
                ['alt-G'] = 'last',
                -- Only valid with fzf previewers (bat/cat/git/etc)
                ['f3'] = 'toggle-preview-wrap',
                ['f4'] = 'toggle-preview',
                ['shift-down'] = 'preview-page-down',
                ['shift-up'] = 'preview-page-up',
            },
        },

        fzf_opts = {
            -- options are sent as `<left>=<right>`
            -- set to `false` to remove a flag
            -- set to `true` for a no-value flag
            -- for raw args use `fzf_args` instead
            ['--ansi'] = true,
            ['--info'] = 'inline-right', -- fzf < v0.42 = "inline"
            ['--height'] = '100%',
            ['--layout'] = 'reverse',
            ['--border'] = 'none',
            ['--highlight-line'] = true, -- fzf >= v0.53
        },
    },
    config = function(_, opts)
        local Fzf = require 'fzf-lua'
        local PickerOpt = {
            defaults = {
                prompt = '> ',
            },
            files = {
                cwd_prompt = false,
            },
        }
        local FinalOpt = vim.tbl_extend('force', opts, PickerOpt)
        Fzf.setup(FinalOpt)
        Fzf.register_ui_select {
            winopts = {
                height = 0.4,
                width = 0.4,
                row = 0.5,
                col = 0.5,
                border = 'rounded',
            },
        }
    end,
}

return FzfLua

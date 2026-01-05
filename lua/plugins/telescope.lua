-- Fuzzy finder

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local focus_preview = function(prompt_bufnr)
    local action_state = require 'telescope.actions.state'
    local picker = action_state.get_current_picker(prompt_bufnr)
    local prompt_win = picker.prompt_win
    local previewer = picker.previewer
    local bufnr = previewer.state.bufnr or previewer.state.termopen_bufnr
    local winid = previewer.state.winid or vim.fn.win_findbuf(bufnr)[1]
    vim.keymap.set({ 'n', 'i' }, '<C-l>', function()
        vim.cmd(string.format('noautocmd lua vim.api.nvim_set_current_win(%s)', prompt_win))
    end, { buffer = bufnr })
    vim.cmd(string.format('noautocmd lua vim.api.nvim_set_current_win(%s)', winid))
    -- api.nvim_set_current_win(winid)
end

---@type LazyPluginSpec
local Telescope = {
    'nvim-telescope/telescope.nvim',
    lazy = true,
    cmd = { 'Telescope' },
    dependencies = {
        'nvim-telescope/telescope-ui-select.nvim',
        {
            'nvim-telescope/telescope-fzf-native.nvim',
            build = 'make',
        },
    },
    config = function()
        ---@module 'telescope'
        require('telescope').setup {
            extensions = {
                ['ui-select'] = {
                    require('telescope.themes').get_dropdown {
                        -- even more opts
                    },
                    -- pseudo code / specification for writing custom displays, like the one
                    -- for "codeactions"
                    -- specific_opts = {
                    --   [kind] = {
                    --     make_indexed = function(items) -> indexed_items, width,
                    --     make_displayer = function(widths) -> displayer
                    --     make_display = function(displayer) -> function(e)
                    --     make_ordinal = function(e) -> string
                    --   },
                    --   -- for example to disable the custom builtin "codeactions" display
                    --      do the following
                    --   codeactions = false,
                    -- }
                },
                fzf = {
                    fuzzy = true, -- false will only do exact matching
                    override_generic_sorter = true, -- override the generic sorter
                    override_file_sorter = true, -- override the file sorter
                    case_mode = 'smart_case', -- or "ignore_case" or "respect_case"
                    -- the default case_mode is "smart_case"
                },
            },
            defaults = {
                layout_config = {
                    prompt_position = 'top',
                },
                sorting_strategy = 'ascending',
                file_ignore_patterns = {
                    'logs',
                    '%.root',
                    '%.gif',
                    '%.pdf',
                    '%.png',
                    '%.jpg',
                    '%.jpeg',
                    '%.vcxproj',
                    '%.vcproj',
                    '%.notes',
                    '%.rst',
                    '%.bat',
                    '%.cmake',
                    'Online.*%.xml',
                },
                mappings = {
                    n = {
                        ['<C-l>'] = focus_preview,
                    },
                    i = {
                        ['<C-l>'] = focus_preview,
                    },
                },
            },
            pickers = {
                git_status = {
                    git_icons = {
                        added = '',
                        deleted = '',
                        changed = '',
                        copied = '›',
                        renamed = '→',
                        unmerged = '',
                        untracked = '?',
                    },
                },
            },
        }
        local mocha = require('catppuccin.palettes').get_palette 'mocha'
        vim.api.nvim_set_hl(0, 'TelescopeResultsDiffAdd', { fg = mocha.green })
        vim.api.nvim_set_hl(0, 'TelescopeResultsDiffChange', { fg = mocha.yellow })
        vim.api.nvim_set_hl(0, 'TelescopeResultsDiffDelete', { fg = mocha.red })
        vim.api.nvim_set_hl(0, 'TelescopeResultsDiffUntracked', { fg = mocha.lavender })
        require('telescope').load_extension 'ui-select'
        require('telescope').load_extension 'fzf'
    end,
}

return Telescope

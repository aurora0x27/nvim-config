-- File system explorer

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local NeoTree = {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    lazy = true,
    cmd = { 'Neotree' },
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-tree/nvim-web-devicons',
        'MunifTanjim/nui.nvim',
    },

    config = function()
        require('neo-tree').setup {
            close_if_last_window = true,
            enable_git_status = true,
            enable_diagnostics = true,

            sources = { 'filesystem', 'buffers', 'git_status' },

            source_selector = {
                winbar = true,
                statusline = false,
                show_separator_on_edge = true,
                separator = { left = ' ', right = '' },
                sources = {
                    { source = 'filesystem', display_name = ' 󰉓 Files' },
                    { source = 'buffers', display_name = ' 󰈙 Buf' },
                    { source = 'git_status', display_name = '󰊢 Git ' },
                },
            },

            window = {
                width = 30,
                mappings = {
                    ['<Tab>'] = 'next_source',
                    ['<S-Tab>'] = 'prev_source',
                    ['l'] = 'open',
                },
            },

            filesystem = {
                follow_current_file = { enabled = true },
                hijack_netrw = true,
                -- hijack_netrw_behavior = "open_default",
                renderers = {
                    directory = {
                        { 'icon' },
                        { 'name' },
                    },
                    file = {
                        {
                            'icon',
                            zindex = 10,
                        },
                        {

                            'container',
                            width = '100%',
                            content = {
                                {
                                    'name',
                                    zindex = 10,
                                },
                                {
                                    'diagnostics',
                                    align = 'right',
                                    zindex = 40,
                                    overlap = true,
                                },
                                {
                                    'git_status',
                                    align = 'right',
                                    zindex = 40,
                                    overlap = true,
                                },
                            },
                        },
                    },
                },
            },

            default_component_configs = {
                icon = {
                    folder_closed = '',
                    folder_open = '',
                    folder_empty = '',
                    default = '',
                    highlight = 'NeoTreeFileIcon',
                },
                git_status = {
                    symbols = {
                        added = '',
                        deleted = '',
                        modified = '',
                        renamed = '➜',
                        untracked = '★',
                        ignored = '◌',
                        unstaged = '✗',
                        staged = '✓',
                        conflict = '',
                    },
                },

                diagnostics = {
                    enable = true,
                    show_on_dirs = true,
                    severity = {
                        min = vim.diagnostic.severity.HINT,
                        max = vim.diagnostic.severity.ERROR,
                    },
                    symbols = {
                        hint = ' ',
                        info = ' ',
                        warn = ' ',
                        error = ' ',
                    },
                },
            },
        }
    end,
}

return NeoTree

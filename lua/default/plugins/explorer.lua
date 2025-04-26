-- File system explorer

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    event = 'VeryLazy',
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

            window = {
                width = 30,
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

        vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>', {
            desc = 'Toggle NeoTree file explorer',
            noremap = true,
            silent = true,
        })
    end,
}

-- return {
--     "mikavilpas/yazi.nvim",
--     event = "VeryLazy",
--     dependencies = {
--         -- check the installation instructions at
--         -- https://github.com/folke/snacks.nvim
--         -- "folke/snacks.nvim"
--     },
--     keys = {
--         -- 👇 in this section, choose your own keymappings!
--         -- {
--         --     "<leader>-",
--         --     mode = { "n", "e" },
--         --     "<cmd>Yazi<cr>",
--         --     desc = "Open yazi at the current file",
--         -- },
--         {
--             -- Open in the current working directory
--             "<leader>e",
--             "<cmd>Yazi cwd<cr>",
--             desc = "Open the file manager in nvim's working directory",
--         },
--         {
--             "<c-up>",
--             "<cmd>Yazi toggle<cr>",
--             desc = "Resume the last yazi session",
--         },
--     },
--     ---@type YaziConfig | {}
--     opts = {
--         -- if you want to open yazi instead of netrw, see below for more info
--         open_for_directories = false,
--         keymaps = {
--             show_help = "<f1>",
--         },
--     },
--     -- 👇 if you use `open_for_directories=true`, this is recommended
--     init = function()
--         -- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
--         -- vim.g.loaded_netrw = 1
--         vim.g.loaded_netrwPlugin = 1
--     end,
-- }

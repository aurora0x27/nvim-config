-- File system explorer

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

---@type LazyPluginSpec
local NeoTree = {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'main',
    lazy = true,
    cmd = { 'Neotree' },
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-tree/nvim-web-devicons',
        'MunifTanjim/nui.nvim',
    },
    opts = {
        close_if_last_window = true,
        enable_git_status = true,
        enable_diagnostics = true,

        sources = { 'filesystem', 'buffers', 'git_status', 'document_symbols' },

        source_selector = {
            winbar = true,
            statusline = false,
            show_separator_on_edge = true,
            separator = { left = ' ', right = '' },
            sources = {
                { source = 'filesystem', display_name = ' 󰉓 Fs' },
                { source = 'document_symbols', display_name = '  Sym' },
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
                ['<CR>'] = 'toggle_node',

                -- Stop warning invalid action
                ['<C-r>'] = '',
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

        document_symbols = {
            follow_cursor = true,
        },

        default_component_configs = {
            icon = {
                folder_closed = '',
                folder_open = '',
                folder_empty = '',
                default = '',
                provider = function(icon, node, _) -- default icon provider utilizes nvim-web-devicons if available
                    if node.type == 'root' then
                        local success, web_devicons = pcall(require, 'nvim-web-devicons')
                        if success then
                            local devicon, _ = web_devicons.get_icon 'dot'
                            icon.text = devicon or icon.text
                            icon.highlight = 'NeoTreeDirectoryIcon'
                        end
                        return
                    end
                    if node.type == 'file' or node.type == 'terminal' then
                        local success, web_devicons = pcall(require, 'nvim-web-devicons')
                        local name = node.type == 'terminal' and 'terminal' or node.name
                        if success then
                            local devicon, hl = web_devicons.get_icon(name)
                            icon.text = devicon or icon.text
                            icon.highlight = hl or icon.highlight
                        end
                    end
                end,
                highlight = 'NeoTreeFileIcon',
            },

            git_status = {
                symbols = {
                    added = '',
                    deleted = '',
                    modified = '',
                    renamed = '󰁔',
                    untracked = '★',
                    ignored = '◌',
                    unstaged = '',
                    staged = '',
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
    },
}

return NeoTree

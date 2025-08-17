-- Float window ui

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local Noice = {
    'folke/noice.nvim',
    event = 'VeryLazy',
    dependencies = {
        'MunifTanjim/nui.nvim',
        'rcarriga/nvim-notify',
    },
    config = function()
        require('noice').setup {
            cmdline = {
                enabled = true,
                view = 'cmdline_popup',
                format = {
                    cmdline = { icon = '' },
                    search_down = { icon = ' ' },
                    search_up = { icon = ' ' },
                    filter = { icon = '$' },
                    lua = { icon = '' },
                    help = { icon = '' },
                },
            },
            messages = {
                enabled = true,
                view = 'notify',
            },
            popupmenu = {
                enabled = true,
                backend = 'nui',
            },
            lsp = {
                hover = {
                    enabled = false,
                    opts = {
                        border = { style = 'rounded' },
                        win_options = {
                            winbar = nil,
                        },
                    },
                },
                override = {
                    ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
                    ['vim.lsp.util.stylize_markdown'] = true,
                    ['cmp.entry.get_documentation'] = true,
                },
            },
            presets = {
                bottom_search = false,
                command_palette = true,
                long_message_to_split = true,
                inc_rename = false,
                lsp_doc_border = true,
            },
        }
    end,
}

return Noice

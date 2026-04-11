--------------------------------------------------------------------------------
-- Float window ui, command line popup
--------------------------------------------------------------------------------

---@type LazyPluginSpec
local Noice = {
    'folke/noice.nvim',
    event = 'VeryLazy',
    dependencies = {
        'MunifTanjim/nui.nvim',
        'rcarriga/nvim-notify',
    },
    ---@module 'noice'
    ---@type NoiceConfig
    opts = {
        cmdline = {
            enabled = false,
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
            enabled = false,
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
            signature = {
                enabled = false,
            },
            override = {
                ['vim.lsp.util.convert_input_to_markdown_lines'] = false,
                ['vim.lsp.util.stylize_markdown'] = false,
                ['cmp.entry.get_documentation'] = false,
            },
        },
    },
}

return Noice

return {
    "akinsho/bufferline.nvim",
    dependencies = "nvim-tree/nvim-web-devicons", -- 需要图标支持
    config = function()
        require("bufferline").setup({
            highlights = require("catppuccin.groups.integrations.bufferline").get(),
            options = {
                -- diagnostics = "nvim_lsp", -- 显示 LSP 诊断信息
                offsets = {
                    {
                        filetype = "neo-tree",
                        text = "File Explorer",
                        separator = true -- use a "true" to enable the default, or set your own character
                    },
                },
            },
        })
    end,
}

if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE
return {
    "akinsho/bufferline.nvim",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
        require("bufferline").setup({
            highlights = require("catppuccin.groups.integrations.bufferline").get(),
            options = {
                -- diagnostics = "nvim_lsp",
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

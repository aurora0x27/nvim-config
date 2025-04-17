-- Tabline

return {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
        require("bufferline").setup({
            highlights = require("catppuccin.groups.integrations.bufferline").get(),
            options = {
                offsets = {
                    {
                        filetype = "neo-tree",
                        text = "File Explorer",
                        separator = true,
                        text_align = "center",
                    },
                    {
                        filetype = "alpha",
                        text = "",
                        separator = false,
                    },
                }
            }
        })


        vim.api.nvim_create_autocmd("FileType", {
            pattern = "alpha",
            callback = function()
                vim.opt.showtabline = 0
            end,
        })

        vim.api.nvim_create_autocmd("BufEnter", {
            callback = function()
                if vim.bo.filetype ~= "alpha" then
                    vim.opt.showtabline = 2
                end
            end,
        })
    end
}

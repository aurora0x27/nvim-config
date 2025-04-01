return {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
        "MunifTanjim/nui.nvim",
        "rcarriga/nvim-notify",
    },
    config = function()
        require("noice").setup({
            cmdline = {
                enabled = true,  -- 啟用浮動命令行
                view = "cmdline_popup",  -- 使用浮動窗口樣式
                format = {
                    cmdline = { icon = "" },
                    search_down = { icon = " " },
                    search_up = { icon = " " },
                    filter = { icon = "$" },
                    lua = { icon = "" },
                    help = { icon = "" },
                },
            },
            messages = {
                enabled = true,
                view = "notify",  -- 使用 `nvim-notify` 來顯示消息
            },
            popupmenu = {
                enabled = true,
                backend = "nui",  -- 使用 `nui.nvim` 來美化補全菜單
            },
            lsp = {
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                    ["cmp.entry.get_documentation"] = true,
                },
            },
            presets = {
                bottom_search = false,  -- 禁用底部搜索
                command_palette = true,  -- 啟用命令面板
                long_message_to_split = true,
                inc_rename = false,
                lsp_doc_border = false,
            },
        })
    end
}

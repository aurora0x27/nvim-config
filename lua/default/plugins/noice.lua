-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

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
                hover = {
                    enabled = true,  -- 允許 noice 接管 hover
                    opts = {
                        border = { style = "single" },  -- 邊框樣式
                        win_options = {
                            winbar = nil,  -- 明確禁用 Winbar
                        },
                    },
                },
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

-- ---@diagnostic disable: missing-fields
-- return {
--     'folke/noice.nvim',
--     keys = { ':', '/', '?' }, -- lazy load cmp on more keys along with insert mode
--     config = function()
--         require('noice').setup {
--             presets = {
--                 command_palette = false,
--                 lsp_doc_border = {
--                     views = {
--                         hover = {
--                             border = {
--                                 style = 'single',
--                             },
--                         },
--                     },
--                 },
--             },
--             messages = {
--                 enabled = true,
--             },
--             popupmenu = {
--                 enabled = true,
--             },
--             lsp = {
--                 signature = {
--                     enabled = false,
--                 },
--                 progress = {
--                     enabled = false,
--                 },
--                 hover = {
--                     enabled = false,
--                 },
--             },
--         }
--     end,
-- }

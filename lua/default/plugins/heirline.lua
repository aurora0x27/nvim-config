-- Status line
return {
    'rebelot/heirline.nvim',
    opts = function(_, opts)
        local conditions = require("heirline.conditions")
        local utils = require("heirline.utils")
        
        local mocha = require("catppuccin.palettes").get_palette("mocha") -- 选择 "mocha" 配色

        -- 颜色定义
        local colors = {
            normal   = mocha.blue,
            insert   = mocha.green,
            visual   = mocha.mauve,
            replace  = mocha.red,
            command  = mocha.peach,
            text_fg  = mocha.text,   -- 默认前景色
            bg       = mocha.base,   -- 默认背景色
        }

        -- 模式指示器
        local ViMode = {
            init = function(self)
                self.mode = vim.fn.mode()
            end,
            provider = function(self)
                local mode_map = {
                    n = "NORMAL",
                    i = "INSERT",
                    v = "VISUAL",
                    V = "V-LINE",
                    c = "COMMAND",
                    R = "REPLACE",
                }
                return " " .. (mode_map[self.mode] or self.mode) .. " "
            end,
            hl = function(self)
                local mode_hl = {
                    n = colors.normal,
                    i = colors.insert,
                    v = colors.visual,
                    V = colors.visual,
                    c = colors.command,
                    R = colors.replace,
                }
                return { fg = "black", bg = mode_hl[self.mode] or colors.normal, bold = true }
            end,
            update = {
                "ModeChanged",
                pattern = "*:*",
                callback = vim.schedule_wrap(function()
                    vim.cmd("redrawstatus")
                end),
            },
        }

        -- -- 文件类型指示器
        -- local FileType = {
        --     provider = function()
        --         return "  " .. vim.bo.filetype .. " "
        --     end,
        --     hl = { fg = mocha.mauve, bold = true },
        -- }

        local FileType = {
            provider = function()
                local filename, extension = vim.fn.expand("%:t"), vim.fn.expand("%:e")
                local icon, icon_color = require("nvim-web-devicons").get_icon_color(filename, extension, { default = true })
                return icon and (" " .. icon .. " " .. vim.bo.filetype .. " ") or (" " .. vim.bo.filetype .. " ")
            end,
            hl = function()
                local _, icon_color = require("nvim-web-devicons").get_icon_color(vim.fn.expand("%:t"), vim.fn.expand("%:e"), { default = true })
                return { fg = icon_color, bold = true }
            end,
        }

        -- 工作目录
        local WorkDir = {
            init = function(self)
                local cwd = vim.fn.getcwd(0)
                self.cwd = vim.fn.fnamemodify(cwd, ":~")
            end,
            provider = function(self)
                return "  " .. self.cwd .. " "
            end,
            hl = { fg = colors.text_fg, bold = true },
        }

        -- LSP 指示器
        local LSP = {
            condition = conditions.lsp_attached,
            provider = function()
                local clients = vim.lsp.get_active_clients()
                if next(clients) == nil then return "" end
                return " " .. clients[1].name .. " "
            end,
            hl = { fg = "cyan", bold = true },
        }

        -- 光标位置
        local CursorPos = {
            provider = function()
                return string.format(" %d:%d ", vim.fn.line("."), vim.fn.col("."))
            end,
            hl = { fg = colors.text_fg, bold = true },
        }

        -- 状态栏结构
        opts.statusline = {
            ViMode,
            FileType,
            WorkDir,
            { provider = "%=" }, -- 居中填充
            LSP,
            CursorPos,
        }

        -- tabline: demonstrate buffers
        opts.tabline = {
            {
              provider = function()
                local buffers = vim.api.nvim_list_bufs()
                local result = " "
                for _, buf in ipairs(buffers) do
                  if vim.api.nvim_buf_get_option(buf, "buflisted") then
                    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
                    local is_active = buf == vim.api.nvim_get_current_buf()
                    if is_active then
                      result = result .. "%#TabLineSel# " .. name .. " %#TabLine#"
                    else
                      result = result .. " " .. name .. " "
                    end
                  end
                end
                return result
              end,
              hl = { fg = "white", bg = "none", bold = true },
            },
        }

        opts.winbar = false

        -- set global status line
        vim.o.laststatus = 3
    end,
}

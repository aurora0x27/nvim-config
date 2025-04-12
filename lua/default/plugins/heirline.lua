-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE
return {
    'rebelot/heirline.nvim',
    opts = function(_, opts)
        local conditions = require("heirline.conditions")

        -- local utils = require("heirline.utils")

        -- import colors from catppuccin
        local mocha = require("catppuccin.palettes").get_palette("mocha")

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

        -- 获取所有 buffer
        local function get_buffers()
            local buffers = {}
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_get_option(buf, "buflisted") then
                    table.insert(buffers, buf)
                end
            end
            return buffers
        end

        local GitStatus = {
            condition = conditions.is_git_repo,
            init = function(self)
                self.status = vim.b.gitsigns_status_dict or {}
            end,
            {
                provider = function(self)
                    local count = self.status.added or 0
                    return count > 0 and (" "..count .. " ") or ""
                end,
                hl = { fg = mocha.green }
            },
            {
                provider = function(self)
                    local count = self.status.changed or 0
                    return count > 0 and (" "..count .. " " ) or ""
                end,
                hl = { fg = mocha.yellow }
            },
            {
                provider = function(self)
                    local count = self.status.removed or 0
                    return count > 0 and (" "..count .. " ") or ""
                end,
                hl = { fg = mocha.red }
            },
            hl = { bg = mocha.bg }
        }

        local Diagnostics = {
            condition = conditions.has_diagnostics,
            init = function(self)
                self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
                self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
                self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
                self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
            end,
            {
                provider = function(self)
                  return self.errors > 0 and (" " .. self.errors .. " ") or ""
                end,
                hl = { fg = mocha.red }
            },
            {
                provider = function(self)
                  return self.warnings > 0 and (" " .. self.warnings .. " ") or ""
                end,
                hl = { fg = mocha.yellow }
            },
            {
                provider = function(self)
                  return self.hints > 0 and (" " .. self.hints .. " ") or ""
                end,
                hl = { fg = mocha.green }
            },
            hl = { bg = colors.bg }
        }

        -- Mode
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
                return " " .. (mode_map[self.mode] or "V-BLOCK") .. " "
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
                return { fg = "black", bg = mode_hl[self.mode] or colors.visual, bold = true }
            end,
            update = {
                "ModeChanged",
                pattern = "*:*",
                callback = vim.schedule_wrap(function()
                    vim.cmd("redrawstatus")
                end),
            },
        }

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
                return " " .. self.cwd .. " "
            end,
            hl = { fg = colors.text_fg, bold = true },
        }

        -- Lsp status
        local LSP = {
            condition = conditions.lsp_attached,
            provider = function()
                local clients = vim.lsp.get_active_clients()
                if next(clients) == nil then return "" end
                return " " .. clients[1].name .. " "
            end,
            hl = { fg = colors.normal, bold = true },
        }

        -- Cursor position
        local CursorPos = {
            provider = function()
                return string.format(" %d:%d ", vim.fn.line("."), vim.fn.col("."))
            end,
            hl = { fg = colors.text_fg, bold = true },
        }

        -- Status line layout
        opts.statusline = {
            ViMode,
            FileType,
            GitStatus,
            WorkDir,
            { provider = "%=" }, -- 居中填充
            Diagnostics,
            LSP,
            CursorPos,
        }

        -- -- tabline: demonstrate buffers
        -- opts.tabline = {
        --     {
        --       provider = function()
        --         local buffers = vim.api.nvim_list_bufs()
        --         local result = " "
        --         for _, buf in ipairs(buffers) do
        --           if vim.api.nvim_buf_get_option(buf, "buflisted") then
        --             local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
        --             local is_active = buf == vim.api.nvim_get_current_buf()
        --             if is_active then
        --               result = result .. "%#TabLineSel# " .. name .. " %#TabLine#"
        --             else
        --               result = result .. " " .. name .. " "
        --             end
        --           end
        --         end
        --         return result
        --       end,
        --       hl = { fg = "white", bg = "none", bold = true },
        --     },
        -- }

        -- Buffer 组件
        local BufferBlock = {
            init = function(self)
                self.buffers = get_buffers()
            end,
            static = {
                -- 计算当前 buffer 高亮
                get_hl = function(self, buf)
                    return buf == vim.api.nvim_get_current_buf() and { fg = colors.text_fg, bg = colors.active, bold = true }
                        or { fg = colors.text_fg, bg = colors.bg }
                end
            },
            {
                provider = function(self)
                    local result = ""
                    for i, buf in ipairs(self.buffers) do
                        local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
                        local is_active = buf == vim.api.nvim_get_current_buf()
                        local modified = vim.api.nvim_buf_get_option(buf, "modified")

                        local hl = self:get_hl(buf)

                        -- 添加未保存標誌
                        if modified then
                            result = result .. " +"
                        end

                        -- 顯示buffer名稱
                        if is_active then
                            -- 激活的時候帶上'x'代表關閉標誌
                            result = result .. "%#TabLineSel# " .. name .. " %Xx%X "
                        else
                            result = result .. "%#TabLine# " .. name .. " "
                        end
                    end
                    return result
                end,
                hl = { fg = colors.insert, bg = colors.bg },
            }
        }

        local WinBar = {
            condition = function()
                -- 使用预定义的排除列表
                local exclude_ft = {
                    ["neo-tree"] = true,
                    ["TelescopePrompt"] = true,
                    ["qf"] = true,
                    ["help"] = true,
                    ["terminal"] = true,
                    ["toggleterm"] = true,
                    ["NvimTree"] = true,
                    ["nofile"] = true,
                }
              
                return vim.bo.buftype == ""
                    and not exclude_ft[vim.bo.filetype]
                    and not vim.wo.previewwindow
                    and not vim.wo.diff
            end,
            update = { "WinEnter", "BufEnter", "FileType" }, -- 动态更新
            BufferBlock
        }

        require('heirline').setup {
            winbar = WinBar
        }

        -- set global status line
        vim.o.laststatus = 3
    end,
}

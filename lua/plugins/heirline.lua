-- Status line

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local StatusLine = {
    'rebelot/heirline.nvim',
    event = 'VeryLazy',
    config = function()
        local conditions = require 'heirline.conditions'
        -- local utils = require("heirline.utils")

        -- import colors from catppuccin
        local mocha = require('catppuccin.palettes').get_palette 'mocha'

        local colors = {
            normal = mocha.blue,
            insert = mocha.green,
            visual = mocha.mauve,
            replace = mocha.red,
            command = mocha.teal,
            select = mocha.rosewater,
            text_fg = mocha.text,
            bg = mocha.base,
        }

        local GitStatus = {
            condition = conditions.is_git_repo,
            init = function(self)
                self.status = vim.b.gitsigns_status_dict or {}
            end,
            {
                provider = function(self)
                    local count = self.status.added or 0
                    return count > 0 and (' ' .. count .. ' ') or ''
                end,
                hl = { fg = mocha.green },
            },
            {
                provider = function(self)
                    local count = self.status.changed or 0
                    return count > 0 and (' ' .. count .. ' ') or ''
                end,
                hl = { fg = mocha.yellow },
            },
            {
                provider = function(self)
                    local count = self.status.removed or 0
                    return count > 0 and (' ' .. count .. ' ') or ''
                end,
                hl = { fg = mocha.red },
            },
            hl = { bg = mocha.bg },
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
                    return self.errors > 0 and (' ' .. self.errors .. ' ') or ''
                end,
                hl = { fg = mocha.red },
            },
            {
                provider = function(self)
                    return self.warnings > 0 and (' ' .. self.warnings .. ' ') or ''
                end,
                hl = { fg = mocha.yellow },
            },
            {
                provider = function(self)
                    return self.hints > 0 and (' ' .. self.hints .. ' ') or ''
                end,
                hl = { fg = mocha.green },
            },
        }

        -- Mode
        local ctrl_v = string.char(22)
        local ctrl_s = string.char(19)
        local mode_hl = {
            n = colors.normal,
            i = colors.insert,
            v = colors.visual,
            V = colors.visual,
            [ctrl_v] = colors.visual,
            s = colors.select,
            S = colors.select,
            [ctrl_s] = colors.select,
            c = colors.command,
            R = colors.replace,
            t = colors.terminal or colors.insert,
        }
        local ViMode = {
            init = function(self)
                self.mode = vim.fn.mode()
            end,
            provider = function(self)
                local mode_name = {
                    n = 'NORMAL',
                    i = 'INSERT',
                    v = 'VISUAL',
                    V = 'V-LINE',
                    [ctrl_v] = 'V-BLOCK',
                    c = 'COMMAND',
                    s = 'SELECT',
                    S = 'S-LINE',
                    [ctrl_s] = 'S-BLOCK',
                    R = 'REPLACE',
                    t = 'TERMINAL',
                }
                return ' ' .. (mode_name[self.mode] or 'UNKNOWN') .. ' '
            end,
            hl = function(self)
                return { fg = 'black', bg = mode_hl[self.mode] or colors.replace, bold = true }
            end,
            update = {
                'ModeChanged',
                pattern = '*:*',
                callback = vim.schedule_wrap(function()
                    vim.cmd 'redrawstatus'
                end),
            },
        }

        local FileType = {
            provider = function()
                local filename, extension = vim.fn.expand '%:t', vim.fn.expand '%:e'
                local icon, _ = require('nvim-web-devicons').get_icon_color(filename, extension, { default = true })
                return icon and ('  ' .. icon .. ' ' .. vim.bo.filetype .. '  ') or ('  ' .. vim.bo.filetype .. '  ')
            end,
            hl = function()
                local _, icon_color = require('nvim-web-devicons').get_icon_color(
                    vim.fn.expand '%:t',
                    vim.fn.expand '%:e',
                    { default = true }
                )
                return { fg = icon_color, bold = true }
            end,
        }

        local function shorten_cwd(dir)
            local parts = {}
            for p in string.gmatch(dir, '[^/]+') do
                table.insert(parts, p)
            end

            local prefix
            local remaining_parts
            if vim.startswith(dir, '~') then
                prefix = '~'
                remaining_parts = { unpack(parts, 2) }
            else
                prefix = '/' .. parts[1]
                remaining_parts = parts
            end

            if #remaining_parts > 5 then
                local last4 = { unpack(remaining_parts, #remaining_parts - 3, #remaining_parts) }
                return prefix .. '/…' .. '/' .. table.concat(last4, '/')
            else
                return dir
            end
        end

        local WorkDir = {
            init = function(self)
                local cwd = vim.fn.getcwd(0)
                self.cwd = vim.fn.fnamemodify(cwd, ':~')
                self.mode = vim.fn.mode()
            end,
            provider = function(self)
                return '   ' .. shorten_cwd(self.cwd) .. ' '
            end,
            hl = function(self)
                return { fg = 'black', bg = mode_hl[self.mode] or colors.replace, bold = true }
            end,
            update = true,
        }

        -- Lsp status
        local LSP = {
            provider = function()
                if conditions.lsp_attached then
                    local clients = vim.lsp.get_clients()
                    if next(clients) ~= nil then
                        return ' 󰒋 ' .. clients[1].name .. ' '
                    end
                end
                return '󰒏 '
            end,
            hl = { fg = mocha.rosewater, bold = true },
        }

        -- Cursor position
        local CursorPos = {
            provider = function()
                return string.format(' %d:%d ', vim.fn.line '.', vim.fn.col '.')
            end,
            hl = { fg = colors.text_fg, bold = true },
        }

        local ScrollBar = {
            static = {
                sbar = { '▁▁ ', '▂▂ ', '▃▃ ', '▄▄ ', '▅▅ ', '▆▆ ', '▇▇ ', '██ ' },
                spinner = {
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                    ' ',
                },
            },
            provider = function(self)
                -- local chars = setmetatable(self.sbar, {
                --     __index = function()
                --         return '  '
                --     end,
                -- })
                local chars = setmetatable(self.spinner, {
                    __index = function()
                        return ' '
                    end,
                })
                local line_ratio = vim.api.nvim_win_get_cursor(0)[1] / vim.api.nvim_buf_line_count(0)
                local position = math.floor(line_ratio * 100)
                local icon = chars[math.floor(line_ratio * #chars)] .. position
                local limit = 2
                if position <= limit or vim.api.nvim_win_get_cursor(0)[1] == 1 then
                    return '↑ TOP'
                elseif position >= 99 or (vim.api.nvim_buf_line_count(0) - vim.api.nvim_win_get_cursor(0)[1]) == 1 then
                    return '↓ BOT'
                else
                    return string.format('%s', icon) .. '%%'
                end
            end,
            hl = { fg = mocha.rosewater, bold = true },
        }

        local FileInfo = {
            init = function(self)
                self.mode = vim.fn.mode()
            end,
            provider = function()
                local filename = vim.fn.expand '%:t'
                local extension = vim.fn.expand '%:e'
                local present, icons = pcall(require, 'nvim-web-devicons')
                local icon = present and icons.get_icon(filename, extension) or '[None]'
                if vim.api.nvim_win_get_width(0) < 120 then
                    return (vim.bo.modified and '%m' or '') .. icon .. ' '
                end
                return (vim.bo.modified and '%m' or '') .. ' ' .. icon .. ' ' .. filename .. ' '
            end,
            hl = function(self)
                return { fg = mode_hl[self.mode] or colors.replace, bold = true }
            end,
            update = true,
        }

        -- Status line layout
        local StatusLine = {
            ViMode,
            FileType,
            GitStatus,
            ScrollBar,
            CursorPos,
            { provider = '%=' },
            Diagnostics,
            LSP,
            FileInfo,
            WorkDir,
        }

        require('heirline').setup {
            statusline = StatusLine,
        }

        -- set global status line
        vim.o.laststatus = 3
    end,
}

return StatusLine

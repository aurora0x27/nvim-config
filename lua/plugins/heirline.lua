-- Status line

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local StatusLine = {
    'rebelot/heirline.nvim',
    event = 'VeryLazy',
    opts = function(_, opts)
        local conditions = require 'heirline.conditions'
        -- local utils = require("heirline.utils")

        -- import colors from catppuccin
        local mocha = require('catppuccin.palettes').get_palette 'mocha'

        local colors = {
            normal = mocha.blue,
            insert = mocha.green,
            visual = mocha.mauve,
            replace = mocha.red,
            command = mocha.peach,
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
            hl = { bg = colors.bg },
        }

        -- Mode
        local ViMode = {
            init = function(self)
                self.mode = vim.fn.mode()
            end,
            provider = function(self)
                local mode_map = {
                    n = 'NORMAL',
                    i = 'INSERT',
                    v = 'VISUAL',
                    V = 'V-LINE',
                    c = 'COMMAND',
                    R = 'REPLACE',
                }
                return ' ' .. (mode_map[self.mode] or 'V-BLOCK') .. ' '
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
                return { fg = 'black', bg = mode_hl[self.mode] or colors.visual, bold = true }
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
                return icon and (' ' .. icon .. ' ' .. vim.bo.filetype .. ' ') or (' ' .. vim.bo.filetype .. ' ')
            end,
            hl = function()
                local _, icon_color = require('nvim-web-devicons').get_icon_color(vim.fn.expand '%:t', vim.fn.expand '%:e', { default = true })
                return { fg = icon_color, bold = true }
            end,
        }

        local WorkDir = {
            init = function(self)
                local cwd = vim.fn.getcwd(0)
                self.cwd = vim.fn.fnamemodify(cwd, ':~')
            end,
            provider = function(self)
                return ' ' .. self.cwd .. ' '
            end,
            hl = { fg = colors.text_fg, bold = true },
        }

        -- Lsp status
        local LSP = {
            condition = conditions.lsp_attached,
            provider = function()
                local clients = vim.lsp.get_clients()
                if next(clients) == nil then
                    return ''
                end
                return ' ' .. clients[1].name .. ' '
            end,
            hl = { fg = mocha.rosewater, bold = false },
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
                sbar = { '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█' },
            },
            provider = function(self)
                local curr_line = vim.api.nvim_win_get_cursor(0)[1]
                local lines = vim.api.nvim_buf_line_count(0)
                local i = math.floor((curr_line - 1) / lines * #self.sbar) + 1
                return string.rep(self.sbar[i], 2)
            end,
            hl = { fg = mocha.yellow, bg = mocha.base },
        }

        -- Status line layout
        opts.statusline = {
            ViMode,
            FileType,
            GitStatus,
            WorkDir,
            { provider = '%=' },
            Diagnostics,
            LSP,
            CursorPos,
            ScrollBar,
        }

        require('heirline').setup {
            -- winbar = WinBar
        }

        -- set global status line
        vim.o.laststatus = 3
    end,
}

return StatusLine

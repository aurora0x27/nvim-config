local tools = require 'utils.fs'
local get_logical_cwd = tools.get_logical_cwd
local shorten_path = tools.shorten_path

local WorkDir = {
    init = function(self)
        local cwd = get_logical_cwd()
        self.cwd = vim.fn.fnamemodify(cwd, ':~')
        self.mode = vim.fn.mode()
        self.icon = require 'modules.patch'.is_restrict() and '   '
            or '   '
    end,
    provider = function(self)
        if vim.o.columns < 80 then
            return '  '
        end
        return self.icon .. shorten_path(self.cwd) .. ' '
    end,
    hl = function(self)
        return {
            fg = 'black',
            bg = self.mode_hl[self.mode] or 'replace',
            bold = true,
        }
    end,
    update = true,
}

return WorkDir

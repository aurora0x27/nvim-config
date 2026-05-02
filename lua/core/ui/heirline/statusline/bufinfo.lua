local IcoUI = require 'assets.icons'.get('ui')
local IcoMisc = require 'assets.icons'.get('misc')

local BufInfo = {
    static = {
        icon = {
            indent = IcoUI.Tab,
            bar = IcoMisc.Vbar,
        },
    },
    provider = function(self)
        local enc = #vim.bo.fileencoding ~= 0 and (vim.bo.fileencoding .. ' ')
            or ''
        return enc
            .. vim.bo.fileformat
            .. ' '
            .. self.icon.indent
            .. ' '
            .. vim.bo.tabstop
            .. ' '
    end,
    hl = { fg = 'text_fg', italic = true },
    condition = function()
        return vim.o.columns >= 120
    end,
    update = { 'BufEnter' },
}

return BufInfo

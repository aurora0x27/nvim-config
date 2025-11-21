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
        return { fg = self.mode_hl[self.mode] or 'replace', bold = true }
    end,
    update = true,
}

return FileInfo

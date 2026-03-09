local function is_new_file()
    local filename = vim.fn.expand('%')
    return filename ~= ''
        and vim.bo.buftype == ''
        and vim.fn.filereadable(filename) == 0
end

local BufName = {
    init = function(self)
        self.mode = vim.fn.mode()
    end,
    provider = function()
        local filename = vim.fn.expand '%:t'
        local extension = vim.fn.expand '%:e'
        local present, icons = pcall(require, 'nvim-web-devicons')
        local icon = present and icons.get_icon(filename, extension)
            or (#filename > 0 and '' or '[None]')
        if #icon > 0 then
            icon = icon .. ' '
        end
        if #filename > 0 then
            filename = filename .. ' '
        end
        if vim.api.nvim_win_get_width(0) < 120 then
            return (vim.bo.modified and '%m' or '') .. icon .. ' '
        end
        local symbols = {}
        if vim.bo.modified then
            table.insert(symbols, '[+]')
        end
        if vim.bo.readonly == true then
            table.insert(symbols, '[RO]')
        end
        if is_new_file() then
            table.insert(symbols, '[New]')
        end
        local prefix = #symbols > 0 and (table.concat(symbols, '') .. ' ') or ''
        return prefix .. icon .. filename
    end,
    hl = function(self)
        return { fg = self.mode_hl[self.mode] or 'replace', bold = true }
    end,
    update = true,
}

return BufName

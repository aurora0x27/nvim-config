local FileType = {
    provider = function()
        local filename, extension = vim.fn.expand '%:t', vim.fn.expand '%:e'
        local icon, _ = require('nvim-web-devicons').get_icon_color(filename, extension, { default = true })
        return icon and ('  ' .. icon .. ' ' .. vim.bo.filetype .. '  ') or ('  ' .. vim.bo.filetype .. '  ')
    end,
    hl = function()
        local _, icon_color =
            require('nvim-web-devicons').get_icon_color(vim.fn.expand '%:t', vim.fn.expand '%:e', { default = true })
        return { fg = icon_color, bold = true }
    end,
}

return FileType

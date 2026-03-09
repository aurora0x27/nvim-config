-- Cursor position
local CursorPos = {
    provider = function()
        return string.format(' %d:%d ', vim.fn.line '.', vim.fn.col '.')
    end,
    hl = { fg = 'text_fg', bold = true },
    condition = function()
        return vim.api.nvim_win_get_width(0) >= 120
    end,
}

return CursorPos

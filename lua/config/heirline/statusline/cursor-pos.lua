-- Cursor position
local CursorPos = {
    provider = function()
        return string.format(' %d:%d ', vim.fn.line '.', vim.fn.col '.')
    end,
    hl = { fg = 'text_fg', bold = true },
}

return CursorPos

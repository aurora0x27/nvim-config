-- Indent line

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local IndentLine = {
    'lukas-reineke/indent-blankline.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    main = 'ibl',

    opts = {
        whitespace = { remove_blankline_trail = false },
        scope = {
            enabled = true,
            show_start = false,
            show_end = false,
        },
    },
}

return IndentLine

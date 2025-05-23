-- Indent line
return {
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

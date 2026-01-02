-- This file contains options, which is executed after lazy initialization
local Options = {}

Options.opt = {
    relativenumber = false,
    spell = false,
    signcolumn = 'auto',
    wrap = false,
    clipboard = 'unnamedplus',
    termguicolors = true,
    wildmenu = true,
    ssop = 'blank,buffers,curdir,folds,help,tabpages,winsize,terminal',
    ignorecase = true,
    undofile = true,
    undodir = vim.fn.stdpath 'state' .. '/undo',
    scrolloff = 5,
    virtualedit = 'block',
}

function Options.apply()
    -- An ungracefull way to fix neovide terminal color render bug
    if vim.g.neovide then
        vim.g.terminal_color_0 = '#45475a'
        vim.g.terminal_color_1 = '#f38ba8'
        vim.g.terminal_color_2 = '#a6e3a1'
        vim.g.terminal_color_3 = '#f9e2af'
        vim.g.terminal_color_4 = '#89b4fa'
        vim.g.terminal_color_5 = '#f5c2e7'
        vim.g.terminal_color_6 = '#94e2d5'
        vim.g.terminal_color_7 = '#bac2de'
        vim.g.terminal_color_8 = '#585b70'
        vim.g.terminal_color_9 = '#f38ba8'
        vim.g.terminal_color_10 = '#a6e3a1'
        vim.g.terminal_color_11 = '#f9e2af'
        vim.g.terminal_color_12 = '#89b4fa'
        vim.g.terminal_color_13 = '#f5c2e7'
        vim.g.terminal_color_14 = '#94e2d5'
        vim.g.terminal_color_15 = '#a6adc8'
    end

    if require('utils.detect').is_windows() then
        vim.o.shell = 'nu'
        vim.o.shellcmdflag = '-c'
        vim.o.shellquote = ''
        vim.o.shellxquote = ''
        vim.notify 'Run windows clipboard settings'
        vim.g.clipboard = {
            name = 'win32yank',
            copy = {
                ['+'] = 'win32yank.exe -i --crlf',
                ['*'] = 'win32yank.exe -i --crlf',
            },
            paste = {
                ['+'] = 'win32yank.exe -o --lf',
                ['*'] = 'win32yank.exe -o --lf',
            },
            cache_enabled = 0,
        }
    end

    local mocha = require('catppuccin.palettes').get_palette 'mocha'

    if vim.g.transparent_mode then
        vim.api.nvim_set_hl(
            0,
            '@variable',
            vim.tbl_extend(
                'force',
                vim.api.nvim_get_hl(0, { name = '@variable' }),
                { italic = true, fg = mocha.lavender }
            )
        )
    end

    -- set Blink border highlight
    vim.api.nvim_set_hl(0, 'BlinkCmpMenuBorder', { fg = mocha.blue })
    vim.api.nvim_set_hl(0, 'BlinkCmpDocBorder', { fg = mocha.blue })
    vim.api.nvim_set_hl(0, 'BlinkCmpSignatureHelpBorder', { fg = mocha.blue })
    vim.api.nvim_set_hl(0, 'BlinkCmpDocSeparator', { fg = mocha.blue })

    -- Fold text
    vim.api.nvim_set_hl(0, 'CustomFold', { fg = mocha.teal, bold = true, italic = true })

    vim.fn.mkdir(vim.opt.undodir:get()[1], 'p')

    for k, v in pairs(Options.opt) do
        vim.o[k] = v
    end
end

return Options

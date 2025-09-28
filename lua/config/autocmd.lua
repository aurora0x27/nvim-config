-- Define some behaviors

local AutoCmd = {}

function AutoCmd.apply()
    local mocha = require('catppuccin.palettes').get_palette 'mocha'

    -- Highlight yanked text
    vim.api.nvim_create_autocmd('TextYankPost', {
        pattern = '*',
        callback = function()
            vim.highlight.on_yank {
                higroup = 'IncSearch',
                timeout = 200,
            }
        end,
    })

    -- Do not display warnings
    ---@diagnostic disable: duplicate-set-field
    vim.deprecate = function() end

    -- set Blink border highlight
    vim.api.nvim_set_hl(0, 'BlinkCmpMenuBorder', { fg = mocha.blue })
    vim.api.nvim_set_hl(0, 'BlinkCmpDocBorder', { fg = mocha.blue })
    vim.api.nvim_set_hl(0, 'BlinkCmpSignatureHelpBorder', { fg = mocha.blue })
    vim.api.nvim_set_hl(0, 'BlinkCmpDocSeparator', { fg = mocha.blue })

    vim.api.nvim_create_autocmd('BufReadPost', {
        callback = function()
            local mark = vim.api.nvim_buf_get_mark(0, '"')
            local lcount = vim.api.nvim_buf_line_count(0)
            if mark[1] > 0 and mark[1] <= lcount then
                vim.api.nvim_win_set_cursor(0, mark)
            end
        end,
        desc = 'Set cursor to the position where it was last left.',
    })

    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'help',
        callback = function()
            vim.cmd 'wincmd T'
        end,
    })

    -- '*.tmpl' template file in configuration
    vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
        pattern = '*.tmpl',
        callback = function(args)
            local fname = vim.fn.fnamemodify(args.file, ':t')
            local m = fname:match '%.([%w_]+)%.tmpl$'
            if m then
                vim.bo[args.buf].filetype = vim.filetype.match { filename = 'dummy.' .. m } or m
            end
        end,
    })
end

return AutoCmd

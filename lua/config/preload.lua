-- This file contains settings load before initializing lazy
local Preload = {}

function Preload.apply()
    -- set global leader
    vim.g.mapleader = ' '
    vim.g.maplocalleader = ' '

    -- set global transparent_mode
    if not vim.g.neovide then
        vim.g.transparent_mode = true
    end

    -- WARN: put this line here instead of `options.lua`
    -- prevents line number and cursor line appear on
    -- dashboard, so werid.
    vim.opt.number = true
    vim.opt.cursorline = true

    -- Will be covered by ftplugin
    vim.opt.tabstop = 4
    vim.opt.shiftwidth = 4
    vim.opt.expandtab = true
    vim.opt.autoindent = true

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

    -- Treat dae as bash, get highlight
    vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
        pattern = '*.dae',
        callback = function()
            vim.bo.filetype = 'sh'
        end,
    })
end

return Preload

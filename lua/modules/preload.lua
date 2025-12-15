-- This file contains settings load before initializing lazy
local Preload = {}

function Preload.apply()
    -- set global leader
    vim.g.mapleader = ' '
    vim.g.maplocalleader = ' '
    vim.g.transparent_mode = false
    vim.g.session_enabled = true

    if vim.env.NVIM_SESSION_DISABLED and vim.env.NVIM_SESSION_DISABLED == '1' then
        vim.g.session_enabled = false
    end

    local alpha = function()
        return string.format('%x', math.floor(255 * (vim.g.transparency or 0.8)))
    end

    -- set global transparent_mode
    if vim.env.NVIM_TRANSPARENT_MODE and vim.env.NVIM_TRANSPARENT_MODE == '1' then
        if vim.g.neovide then
            vim.g.neovide_window_blurred = true
            vim.g.neovide_opacity = 0.9
            vim.g.neovide_normal_opacity = 0.8
            vim.g.neovide_background_color = '#1e1e2e' .. alpha()
            vim.g.neovide_floating_corner_radius = 0.3
        else
            vim.g.transparent_mode = true
        end
    end

    vim.g.use_emmylua_ls = vim.env.NVIM_USE_EMMYLUA_LS and vim.env.NVIM_USE_EMMYLUA_LS == '1' or false

    -- WARN: put this line here instead of `options.lua`
    -- prevents line number and cursor line appear on
    -- dashboard, so werid.
    vim.o.number = true
    vim.o.cursorline = not vim.g.transparent_mode

    vim.opt.fillchars = {
        eob = ' ',
        diff = '╱',
        foldopen = '',
        foldclose = '',
        foldsep = '▕',
        fold = ' ',
    }

    -- Will be covered by ftplugin
    vim.o.tabstop = 4
    vim.o.shiftwidth = 4
    vim.o.expandtab = true
    vim.o.autoindent = true

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

return Preload

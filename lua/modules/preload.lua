-- This file contains settings load before initializing lazy
local M = {}

local profile = require 'modules.profile'

function M.setup()
    -- set global leader
    vim.g.mapleader = ' '
    vim.g.maplocalleader = ' '

    profile.setup()

    local alpha = function()
        return string.format('%x', math.floor(255 * (vim.g.transparency or 0.8)))
    end

    -- set global transparent_mode
    if profile.transparent_mode and vim.g.neovide then
        vim.g.neovide_window_blurred = true
        vim.g.neovide_opacity = 0.9
        vim.g.neovide_normal_opacity = 0.8
        vim.g.neovide_background_color = '#1e1e2e' .. alpha()
        vim.g.neovide_floating_corner_radius = 0.3
    end

    require('modules.lang').setup {
        blacklist = profile.lang_blacklist,
        whitelist = profile.lang_whitelist,
        levels = profile.lang_levels,
    }

    -- WARN: put this line here instead of `options.lua`
    -- prevents line number and cursor line appear on
    -- dashboard, so werid.
    vim.o.number = true
    vim.o.cursorline = not profile.transparent_mode

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

    -- filetype alias
    vim.filetype.add {
        extension = {
            mdx = 'markdown',
        },
        pattern = {
            -- Add patterns
            -- ['<pattern>'] = '<filetype>',
            ['xmake.lua'] = 'xmake',
        },
    }

    -- register filetype `xmake`
    vim.treesitter.language.register('lua', 'xmake')
    vim.api.nvim_create_autocmd({ 'FileType' }, {
        pattern = 'xmake',
        callback = function()
            vim.treesitter.start()
        end,
    })
end

return M

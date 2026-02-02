-- This file contains settings load before initializing lazy
local M = {}

---@param opt string
---@return boolean
local function check_env_opt(opt)
    return vim.env[opt] and vim.env[opt] == '1'
end

function M.setup()
    -- set global leader
    vim.g.mapleader = ' '
    vim.g.maplocalleader = ' '
    vim.g.transparent_mode = false
    vim.g.session_enabled = true

    if check_env_opt 'NVIM_SESSION_DISABLED' then
        vim.g.session_enabled = false
    end

    local alpha = function()
        return string.format('%x', math.floor(255 * (vim.g.transparency or 0.8)))
    end

    -- set global transparent_mode
    if check_env_opt 'NVIM_TRANSPARENT_MODE' then
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

    vim.g.diag_inline = check_env_opt 'NVIM_DIAGNOSTIC_INLINE' or false
    vim.g.inject_vim_rt = check_env_opt 'NVIM_WORKSPACE_INJECT_VIM_RT' or true
    vim.g.inject_plugin_path = check_env_opt 'NVIM_WORKSPACE_INJECT_PLUGIN_PATH' or false
    vim.g.enable_xmake_ls = check_env_opt 'NVIM_ENABLE_XMAKE_LS' or false
    vim.g.use_emmylua_ls = check_env_opt 'NVIM_USE_EMMYLUA_LS' or false
    vim.g.enable_java_ls = check_env_opt 'NVIM_ENABLE_JAVA_LS' or false
    vim.g.enable_gopls = check_env_opt 'NVIM_ENABLE_GOPLS' or false
    vim.g.disable_im_switch = check_env_opt 'NVIM_DISABLE_IM_SWITCH' or false
    vim.g.enable_lsp = check_env_opt 'NVIM_ENABLE_LSP' or vim.fn.has('nvim-0.11') == 1
    vim.g.enable_current_line_blame = check_env_opt 'NVIM_ENABLE_GIT_LINE_BLAME' or false

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

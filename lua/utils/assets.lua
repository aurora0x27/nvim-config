local M = {}

M.RawDiagnosticSpec = {
    [vim.diagnostic.severity.ERROR] = {
        icon = '󰅚 ',
        hl = 'DiagnosticError',
    },
    [vim.diagnostic.severity.WARN] = {
        icon = '󰀪 ',
        hl = 'DiagnosticWarn',
    },
    [vim.diagnostic.severity.INFO] = {
        icon = '󰋽 ',
        hl = 'DiagnosticInfo',
    },
    [vim.diagnostic.severity.HINT] = {
        icon = '󰌶 ',
        hl = 'DiagnosticHint',
    },
}

-- TODO: replace all the hard coded style
-- Border style of floating windows
M.border = 'rounded'

M.ProfileSchema = {
    session_disabled = false,
    transparent_mode = false,
    diagnose_inline = false,
    dashboard_art_name = 'Ayanami Rei',
    workspace_inject_vim_rt = true,
    workspace_inject_plugin_path = false,
    use_emmylua_ls = false,
    disable_im_switch = false,
    enable_lsp = vim.fn.has 'nvim-0.11' == 1,
    enable_current_line_blame = false,
    blink_use_binary = false,
    silent_lang_diag = false,
    silent_profile_diag = false,
    lang_blacklist = '',
    lang_whitelist = '',
    lang_levels = '',
    statline_scrollbar_style = 'moon',
}

return M

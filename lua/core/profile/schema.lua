return {
    sandbox_mode = 'none', -- experimental sandbox mode
    transparent_mode = false,
    diagnose_mode = 'inline', -- 'inline'|'detailed'|'pretty'
    diagnose_level = 'hint', -- 'hint'|'info'|'warn'|'error'
    diagnose_with_fancy_underline = false,
    dashboard_art_name = 'Ayanami Rei',
    workspace_inject_vim_rt = true,
    workspace_inject_plugin_path = false,
    use_emmylua_ls = false,
    disable_im_switch = false,
    enable_lsp = vim.fn.has 'nvim-0.11' == 1,
    enable_inlay_hint = false,
    enable_current_line_blame = false,
    blink_use_binary = true,
    lang_blacklist = 'all',
    lang_whitelist = '',
    lang_levels = '',
    statline_scrollbar_style = 'moon',
    bigfile_size_byte = 2097152, -- 2MB
    bigfile_size_line = 100000,
    allow_workspace_patch = false,
    workspace_patch_always_restrict = true,
    enable_dropbar = false,
    clang_format_path = 'clang-format',
    clangd_path = 'clangd',
}

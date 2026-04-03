local M = {}

-- TODO: replace all the hard coded style
-- Border style of floating windows
M.border = 'rounded'

M.ProfileSchema = {
    sandbox_mode = 'none', -- experimental sandbox mode
    transparent_mode = false,
    diagnose_inline = false,
    dashboard_art_name = 'Ayanami Rei',
    workspace_inject_vim_rt = true,
    workspace_inject_plugin_path = false,
    use_emmylua_ls = false,
    disable_im_switch = false,
    enable_lsp = vim.fn.has 'nvim-0.11' == 1,
    enable_current_line_blame = false,
    blink_use_binary = true,
    silent_lang_diag = false,
    silent_profile_diag = false,
    lang_blacklist = 'all',
    lang_whitelist = '',
    lang_levels = '',
    statline_scrollbar_style = 'moon',
    bigfile_size_byte = 2097152, -- 2MB
    bigfile_size_line = 100000,
    allow_workspace_patch = false,
    workspace_patch_always_restrict = true,
    enable_dropbar = false,
}

M.ColorAlias = {
    rosewater = '#f5e0dc',
    flamingo = '#f2cdcd',
    pink = '#f5c2e7',
    mauve = '#cba6f7',
    red = '#f38ba8',
    maroon = '#eba0ac',
    peach = '#fab387',
    yellow = '#f9e2af',
    green = '#a6e3a1',
    teal = '#94e2d5',
    sky = '#89dceb',
    sapphire = '#74c7ec',
    blue = '#89b4fa',
    lavender = '#b4befe',
    text = '#cdd6f4',
    subtext1 = '#bac2de',
    subtext0 = '#a6adc8',
    overlay2 = '#9399b2',
    overlay1 = '#7f849c',
    overlay0 = '#6c7086',
    surface2 = '#585b70',
    surface1 = '#45475a',
    surface0 = '#313244',
    base = '#1e1e2e',
    mantle = '#181825',
    crust = '#11111b',
}

return M

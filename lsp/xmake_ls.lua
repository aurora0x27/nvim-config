---@type vim.lsp.Config
local xmake_ls = {
    cmd = { 'xmake_ls' },
    filetypes = Lang.lsp_get_ft 'xmake_ls',
    root_markers = {
        'clice.toml',
        '.clang-tidy',
        '.clang-format',
        'compile_commands.json',
        'compile_flags.txt',
        '.git',
    },
}

return xmake_ls

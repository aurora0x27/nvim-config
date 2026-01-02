---@type vim.lsp.Config
local xmake_ls = {
    cmd = { 'xmake_ls' },
    filetypes = { 'xmake' },
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

---@type LangSpec
return {
    treesitter = 'lua',
    lsp = vim.g.use_emmylua_ls and { name = 'emmylua_ls', source = 'sys' } or { name = 'lua_ls', packname = 'lua-language-server' },
}

---@type LangSpec[]
return {
  {
    ft = 'lua',
    treesitter = true,
    formatter = { name = 'stylua' },
    lsp = Profile.use_emmylua_ls and { name = 'emmylua_ls', source = 'sys' }
      or { name = 'lua_ls', packname = 'lua-language-server' },
    plugins = 'lazydev',
  },
  {
    ft = 'xmake',
    treesitter = 'lua',
    lsp = { name = 'xmake_ls', source = 'sys' },
  },
}

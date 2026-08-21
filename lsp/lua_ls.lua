-- Lua lsp

---@type vim.lsp.Config
local lua_ls = {
  cmd = { 'lua-language-server' },
  filetypes = Lang.lsp_get_ft 'lua_ls',
  root_dir = require 'utils.fs'.cwd(),
  workspace_required = false,
  settings = {
    Lua = {
      hint = { enable = true },
      runtime = {
        version = 'LuaJIT',
      },
    },
  },
}

return lua_ls

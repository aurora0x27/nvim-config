---@type vim.lsp.Config
local xmake_ls = {
  cmd = { 'xmake_ls' },
  filetypes = Lang.lsp_get_ft 'xmake_ls',
  root_dir = require 'utils.fs'.cwd(),
}

return xmake_ls

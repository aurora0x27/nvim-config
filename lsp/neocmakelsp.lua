---@type vim.lsp.Config
local NeoCMake = {
  cmd = { 'neocmakelsp', 'stdio' },
  filetypes = Lang.lsp_get_ft 'neocmakelsp',
  root_dir = require 'utils.fs'.cwd(),
}

return NeoCMake

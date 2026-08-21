---@brief
--- https://github.com/zigtools/zls
---
--- Zig LSP implementation + Zig Language Server

---@type vim.lsp.Config
return {
  cmd = { 'zls' },
  filetypes = Lang.lsp_get_ft 'zls',
  root_dir = require 'utils.fs'.cwd(),
  workspace_required = false,
}

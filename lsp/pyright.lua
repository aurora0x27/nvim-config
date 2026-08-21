---@type vim.lsp.Config
local pyright = {
  filetypes = Lang.lsp_get_ft 'pyright',
  cmd = { 'pyright-langserver', '--stdio' },
  workspace_required = false,
  root_dir = require 'utils.fs'.cwd(),
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = 'openFilesOnly',
        useLibraryCodeForTypes = true,
      },
    },
  },
}

return pyright

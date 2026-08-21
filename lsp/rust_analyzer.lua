---@type vim.lsp.Config
local rust_analyzer = {
  filetypes = Lang.lsp_get_ft 'rust_analyzer',
  root_dir = require 'utils.fs'.cwd(),
  settings = {
    ['rust_analyzer'] = {
      diagnostics = {
        enable = true,
        experimental = {
          enable = true,
        },
      },
      check = {
        command = 'clippy',
        extraArgs = { '--all-targets' },
        on = 'on_type',
      },
      cargo = {
        buildScripts = {
          enable = true,
        },
      },
      proMacro = {
        enable = true,
      },
    },
  },
  capabilities = {
    experimental = {
      serverStatusNotification = false,
    },
  },
  cmd = {
    'rust-analyzer',
  },
}

return rust_analyzer

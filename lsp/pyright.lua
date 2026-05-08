local pyright = {
  filetypes = Lang.lsp_get_ft 'pyright',
  cmd = { 'pyright-langserver', '--stdio' },
  workspace_required = false,
  root_markers = {
    '.venv',
    'uv.lock',
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'Pipfile',
    'pyrightconfig.json',
    '.git',
  },
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

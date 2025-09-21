local pyright = {
    filetypes = { 'python' },
    cmd = { 'pyright-langserver', '--stdio' },
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

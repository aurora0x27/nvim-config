local NeoCMake = {
    cmd = { 'neocmakelsp', 'stdio' },
    filetypes = Lang.lsp_get_ft 'neocmakelsp',
    root_markers = { '.git', 'build', 'cmake' },
}

return NeoCMake

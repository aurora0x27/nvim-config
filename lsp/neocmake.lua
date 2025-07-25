local NeoCMake = {
    cmd = { 'neocmakelsp', '--stdio' },
    filetypes = { 'cmake' },
    root_markers = { '.git', 'build', 'cmake' },
}

return NeoCMake

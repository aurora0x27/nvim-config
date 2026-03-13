local NeoCMake = {
    cmd = { 'neocmakelsp', 'stdio' },
    filetypes = require 'modules.lang'.lsp_get_ft 'neocmakelsp',
    root_markers = { '.git', 'build', 'cmake' },
}

return NeoCMake

-- NOTE: For experimental use and devlopment, Clice is not availabe now.

local clice = {
    filetypes = { 'c', 'cpp' },

    root_markers = {
        '.git/',
        'clice.toml',
        '.clang-tidy',
        '.clang-format',
        'compile_commands.json',
        'compile_flags.txt',
        'configure.ac', -- AutoTools
    },

    capabilities = {
        textDocument = {
            completion = {
                editsNearCursor = true,
            },
        },
        offsetEncoding = { 'utf-8' },
    },

    cmd = {
        'clice',
        '--mode=pipe',
        '--resource-dir=/home/aurora/Applications/apps/opt/llvm-21/',
    },
}

return clice

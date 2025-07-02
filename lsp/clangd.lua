-- Clangd for c/cpp dev

local clangd = {
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
        'clangd',
        '--background-index',
        '--clang-tidy',
        '--header-insertion=iwyu',
        '--completion-style=detailed',
        '--function-arg-placeholders=true',
        '-j=4',
        '--fallback-style="{BasedOnStyle: LLVM, IndentWidth: 4}"',
    },

    init_options = {
        usePlaceholders = true,
        completeUnimported = true,
        clangdFileStatus = true,
    },
}

return clangd

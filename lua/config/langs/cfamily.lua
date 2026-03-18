---@type LangSpec[]
return {
    {
        ft = { 'c', 'cpp', 'objc' },
        lsp = { name = 'clangd', source = 'sys' },
        formatter = { name = 'clang-format', source = 'sys' },
        treesitter = true,
    },
    {
        ft = {'objcpp'},
        lsp = { name = 'clangd', source = 'sys' },
        formatter = { name = 'clang-format', source = 'sys' },
        treesitter = false,
    },
}

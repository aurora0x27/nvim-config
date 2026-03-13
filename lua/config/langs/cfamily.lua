---@type ToolSpec
local ClangdSpec = { name = 'clangd', source = 'sys' }
local ClangFormatSpec = { name = 'clang-format', source = 'sys' }

---@type LangSpec[]
return {
    {
        ft = 'c',
        lsp = ClangdSpec,
        formatter = ClangFormatSpec,
        treesitter = true,
    },
    {
        ft = 'cpp',
        lsp = ClangdSpec,
        formatter = ClangFormatSpec,
        treesitter = true,
    },
    {
        ft = 'objc',
        lsp = ClangdSpec,
        formatter = ClangFormatSpec,
        treesitter = true,
    },
}

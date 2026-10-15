---@type LangSpec[]
return {
  {
    ft = { 'c', 'cpp', 'objc' },
    lsp = Profile.use_clice and { name = 'clice', source = 'sys' }
      or { name = 'clangd', source = 'sys' },
    formatter = { name = 'clang-format', source = 'sys' },
    treesitter = true,
  },
  {
    ft = { 'objcpp' },
    lsp = { name = 'clangd', source = 'sys' },
    formatter = { name = 'clang-format', source = 'sys' },
    treesitter = false,
  },
}

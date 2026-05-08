---@type LangSpec
return {
  treesitter = { 'markdown', 'markdown_inline' },
  formatter = { name = 'prettier' },
  plugins = { 'markdown-preview', 'render-markdown' },
}

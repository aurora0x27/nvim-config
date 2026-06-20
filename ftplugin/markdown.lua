if vim.b.did_ftplugin then
  return
end

vim.keymap.set('n', '<F8>', '<cmd>MarkdownPreviewToggle<CR>', {
  desc = 'MarkdownPreviewToggle',
  noremap = true,
  silent = true,
  buffer = true,
})
vim.keymap.set('n', '<leader>p', '<cmd>MarkdownPreviewToggle<CR>', {
  desc = 'MarkdownPreviewToggle',
  noremap = true,
  silent = true,
  buffer = true,
})

vim.b.did_ftplugin = 1

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
vim.bo.shiftwidth = 2
vim.bo.tabstop = 2
vim.bo.softtabstop = 2

vim.b.did_ftplugin = 1

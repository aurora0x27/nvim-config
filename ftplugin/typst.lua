if vim.b.did_ftplugin then
  return
end

vim.keymap.set('n', '<leader>p', '<cmd>TypstPreviewToggle<CR>', {
  desc = 'TypstPreviewToggle',
  noremap = true,
  silent = true,
  buffer = true,
})

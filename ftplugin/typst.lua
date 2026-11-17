if vim.b.did_ftplugin then
  return
end

vim.keymap.set('n', '<leader>lcp', '<cmd>TypstPreviewToggle<CR>', {
  desc = '[P]review',
  noremap = true,
  silent = true,
  buf = 0,
})

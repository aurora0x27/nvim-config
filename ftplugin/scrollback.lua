vim.bo.modifiable = false
vim.keymap.set(
  'n',
  'i',
  [[<cmd>echoerr 'cannot insert in scrollback mode'<cr>]],
  { silent = true, buf = 0 }
)
vim.keymap.set('n', 'q', [[<cmd>q<cr>]], { silent = true, buf = 0 })
vim.wo.number = false
vim.wo.relativenumber = false

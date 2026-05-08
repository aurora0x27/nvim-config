local misc = require 'utils.misc'
local map = vim.keymap.set

----------------------------------------------------------------------------
-- Tab related
----------------------------------------------------------------------------
map(
  { 'n' },
  '<leader>tt',
  '<cmd>tabnext<cr>',
  { noremap = true, silent = true, desc = '[T]ab shif[T]' }
)
map(
  { 'n' },
  '<leader>tnn',
  '<cmd>tabnew<cr>',
  { noremap = true, silent = true, desc = 'Tab [N]ew' }
)
map({ 'n' }, '<leader>tnN', function()
  local name = vim.fn.input('File name: ', '', 'file')
  if name ~= '' then
    vim.cmd('tabnew ' .. name)
  else
    vim.cmd 'tabnew'
    misc.warn 'Warn: Filename not assigned, opening an anonymous buffer'
  end
end, { noremap = true, silent = true, desc = 'Tab [N]ew with name' })
map(
  { 'n' },
  '<leader>tp',
  '<cmd>tabprevious<cr>',
  { noremap = true, silent = true, desc = '[T]ab switch [P]revious' }
)
map({ 'n' }, '<leader>ta', '<cmd>tabnew %<cr>', {
  noremap = true,
  silent = true,
  desc = 'Tab [A]dd With Current Buffer',
})
map(
  { 'n' },
  '<leader>tc',
  '<cmd>tabclose<cr>',
  { noremap = true, silent = true, desc = 'Tab [C]lose' }
)

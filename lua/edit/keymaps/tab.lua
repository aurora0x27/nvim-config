local misc = require 'utils.misc'
local map = vim.keymap.set
local bind = require 'utils.loader'.bind
local LOG_TITLE = 'Tabline'

----------------------------------------------------------------------------
-- Tab related
----------------------------------------------------------------------------
map(
  { 'n' },
  ']t',
  '<cmd>tabnext<cr>',
  { noremap = true, silent = true, desc = '[T]ab shif[T]' }
)

map(
  { 'n' },
  '[t',
  '<cmd>tabprevious<cr>',
  { noremap = true, silent = true, desc = '[T]ab switch [P]revious' }
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

map({ 'n' }, '<leader>ta', '<cmd>tabnew %<cr>', {
  noremap = true,
  silent = true,
  desc = 'Tab [A]dd With Current Buffer',
})

map(
  { 'n' },
  '<leader>tr',
  bind(vim.ui.input, { prompt = 'New Tab Name' }, function(input)
    if input or input == '' then
      require 'core.bpm'.rename_tab(vim.api.nvim_get_current_tabpage(), input)
    else
      vim.notify('Empty input', vim.log.levels.INFO, { title = LOG_TITLE })
    end
  end),
  {
    noremap = true,
    silent = true,
    desc = 'Tab [R]ename',
  }
)

map(
  { 'n' },
  '<leader>tc',
  '<cmd>tabclose<cr>',
  { noremap = true, silent = true, desc = 'Tab [C]lose' }
)

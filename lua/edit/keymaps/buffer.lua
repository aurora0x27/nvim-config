local map = vim.keymap.set
local thunk = require 'utils.loader'.thunk
local bind = require 'utils.loader'.bind
local BufferPoolManager = require 'core.bpm'

----------------------------------------------------------------------------
-- buffer swich
----------------------------------------------------------------------------
map(
  'n',
  '<C-h>',
  thunk('smart-splits', 'move_cursor_left'),
  { desc = 'Move to left window', noremap = true, silent = true }
)
map(
  'n',
  '<C-j>',
  thunk('smart-splits', 'move_cursor_down'),
  { desc = 'Move to below window', noremap = true, silent = true }
)
map(
  'n',
  '<C-k>',
  thunk('smart-splits', 'move_cursor_up'),
  { desc = 'Move to above window', noremap = true, silent = true }
)
map(
  'n',
  '<C-l>',
  thunk('smart-splits', 'move_cursor_right'),
  { desc = 'Move to right window', noremap = true, silent = true }
)

----------------------------------------------------------------------------
-- buffer releated, prefix is leader-b
----------------------------------------------------------------------------
map(
  'n',
  '<leader>bd',
  BufferPoolManager.detach,
  { desc = 'Buffer [D]etach', noremap = true, silent = true }
)

map(
  'n',
  '<leader>bc',
  BufferPoolManager.evict,
  { desc = 'Buffer [C]lose', noremap = true, silent = true }
)

map(
  'n',
  '<leader>bv',
  bind(BufferPoolManager.vacuum, true),
  { desc = 'Buffer [V]acuum', noremap = true, silent = true }
)

----------------------------------------------------------------------------
-- Cycle switch buffer
----------------------------------------------------------------------------
map('n', 'H', '<cmd>bp<cr>', { noremap = true, silent = true })

map('n', 'L', '<cmd>bn<cr>', { noremap = true, silent = true })

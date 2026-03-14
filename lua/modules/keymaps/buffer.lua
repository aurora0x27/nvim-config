local map = vim.keymap.set
local thunk = require 'utils.loader'.thunk
local bind = require 'utils.loader'.bind

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
    '<leader>bc',
    '<cmd>bp | bd #<CR>',
    { desc = 'Buffer [C]lose Current', noremap = true, silent = true }
)

----------------------------------------------------------------------------
-- Cycle switch buffer
----------------------------------------------------------------------------
map(
    'n',
    'H',
    bind(thunk('bufferline', 'cycle'), -1),
    { noremap = true, silent = true }
)

map(
    'n',
    'L',
    bind(thunk('bufferline', 'cycle'), 1),
    { noremap = true, silent = true }
)

----------------------------------------------------------------------------
-- Move buffer
----------------------------------------------------------------------------
map(
    'n',
    '<leader>bh',
    bind(thunk('bufferline', 'move'), -1),
    { noremap = true, silent = true }
)

map(
    'n',
    '<leader>bl',
    bind(thunk('bufferline', 'move'), 1),
    { noremap = true, silent = true }
)

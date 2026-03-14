local map = vim.keymap.set
local thunk = require 'utils.loader'.thunk

----------------------------------------------------------------------------
-- resize window
----------------------------------------------------------------------------
map(
    'n',
    '<C-Left>',
    thunk('smart-splits', 'resize_left'),
    { noremap = true, silent = true }
)
map(
    'n',
    '<C-Right>',
    thunk('smart-splits', 'resize_right'),
    { noremap = true, silent = true }
)
map(
    'n',
    '<C-Up>',
    thunk('smart-splits', 'resize_up'),
    { noremap = true, silent = true }
)
map(
    'n',
    '<C-Down>',
    thunk('smart-splits', 'resize_down'),
    { noremap = true, silent = true }
)

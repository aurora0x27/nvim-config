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

-- TODO: each buffer has a repl env
local buf

---@return integer
local function create_idle_buffer()
  local new_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[new_buf].buftype = 'nofile'
  vim.bo[new_buf].bufhidden = 'hide'
  vim.bo[new_buf].filetype = 'scratch'
  vim.bo[new_buf].swapfile = false
  vim.keymap.set('n', 'q', function()
    vim.cmd 'close'
  end, {
    buf = new_buf,
    silent = true,
    desc = 'Quit buffer',
  })
  return new_buf
end

local function ensure_idle_buffer()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    buf = create_idle_buffer()
  end
  return buf
end

map('n', '<leader>wvbi', function()
  vim.api.nvim_open_win(ensure_idle_buffer(), true, { split = 'right' })
end, { desc = '[I]dle buffer', noremap = true, silent = true })

map('n', '<leader>wsbi', function()
  vim.api.nvim_open_win(
    ensure_idle_buffer(),
    true,
    { split = 'below', height = 10 }
  )
end, { desc = '[I]dle buffer', noremap = true, silent = true })

map('n', '<leader>bi', function()
  vim.api.nvim_open_win(
    ensure_idle_buffer(),
    true,
    { split = 'below', height = 10 }
  )
end, { desc = '[I]dle buffer(split below)', noremap = true, silent = true })

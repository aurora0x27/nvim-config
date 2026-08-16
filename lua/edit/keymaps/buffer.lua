local map = vim.keymap.set
local thunk = require 'utils.fnx'.thunk
local Bpm = require 'core.bpm'

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
  Bpm.detach,
  { desc = '[D]etach', noremap = true, silent = true }
)

map(
  'n',
  '<leader>bc',
  Bpm.evict,
  { desc = '[C]lose', noremap = true, silent = true }
)

----------------------------------------------------------------------------
-- Cycle switch buffer
----------------------------------------------------------------------------
map('n', 'H', '<cmd>bp<cr>', { noremap = true, silent = true })
map(
  'n',
  '[b',
  '<cmd>bp<cr>',
  { noremap = true, silent = true, desc = 'Previous Buffer' }
)
map('n', 'L', '<cmd>bn<cr>', { noremap = true, silent = true })
map(
  'n',
  ']b',
  '<cmd>bn<cr>',
  { noremap = true, silent = true, desc = 'Next Buffer' }
)

-- TODO: each buffer has a repl env
local idle_buf

---@return integer
local function create_idle_buffer()
  local new_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[new_buf].buftype = 'nofile'
  vim.bo[new_buf].bufhidden = 'hide'
  vim.bo[new_buf].filetype = 'scratch-lua'
  vim.bo[new_buf].commentstring = '-- %s'
  vim.bo[new_buf].swapfile = false
  vim.keymap.set('n', 'q', function()
    vim.cmd 'close'
  end, {
    buf = new_buf,
    silent = true,
    desc = 'Quit buffer',
  })
  pcall(vim.treesitter.start, new_buf, 'lua')
  return new_buf
end

local function ensure_idle_buffer()
  if not idle_buf or not vim.api.nvim_buf_is_valid(idle_buf) then
    idle_buf = create_idle_buffer()
  end
  return idle_buf
end

map('n', '<leader>wvbi', function()
  vim.api.nvim_open_win(ensure_idle_buffer(), true, { split = 'right' })
end, { desc = '[I]dle buffer', noremap = true, silent = true })

map('n', '<leader>wsbi', function()
  vim.api.nvim_open_win(
    ensure_idle_buffer(),
    true,
    { split = 'below', height = 10, style = 'minimal' }
  )
end, { desc = '[I]dle buffer', noremap = true, silent = true })

map('n', '<leader>bi', function()
  vim.api.nvim_open_win(
    ensure_idle_buffer(),
    true,
    { split = 'below', height = 10, style = 'minimal' }
  )
end, { desc = '[I]dle buffer(split below)', noremap = true, silent = true })

map('n', '<leader>wvbs', function()
  vim.api.nvim_open_win(create_idle_buffer(), true, { split = 'right' })
end, { desc = '[S]cratch buffer', noremap = true, silent = true })

map('n', '<leader>wsbs', function()
  vim.api.nvim_open_win(
    create_idle_buffer(),
    true,
    { split = 'below', height = 10, style = 'minimal' }
  )
end, { desc = '[S]cratch buffer', noremap = true, silent = true })

map('n', '<leader>bs', function()
  vim.api.nvim_open_win(
    create_idle_buffer(),
    true,
    { split = 'below', height = 10, style = 'minimal' }
  )
end, { desc = '[S]cratch buffer(split below)', noremap = true, silent = true })

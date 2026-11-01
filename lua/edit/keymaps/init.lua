--------------------------------------------------------------------------------
-- This file contains keymaps, which is executed after lazy initialization
--------------------------------------------------------------------------------

local M = {}

local thunk = require 'utils.fnx'.thunk
local bind = require 'utils.fnx'.bind
local map = vim.keymap.set
local LOG_TITLE = 'Keymaps'
local log = require 'utils.logger'.new(LOG_TITLE)

local _initialized = false

function M.setup()
  if _initialized then
    log.error 'Should not initialize module twice'
    return
  end
  require 'edit.keymaps.buffer'
  require 'edit.keymaps.window'
  require 'edit.keymaps.tab'
  require 'edit.keymaps.finder'
  require 'edit.keymaps.persist'

  ----------------------------------------------------------------------------
  -- insert mode move cursor
  ----------------------------------------------------------------------------
  map('i', '<C-j>', '<Down>', { noremap = true, silent = true })
  map('i', '<C-k>', '<Up>', { noremap = true, silent = true })
  map('i', '<C-h>', '<Left>', { noremap = true, silent = true })
  map('i', '<C-l>', '<Right>', { noremap = true, silent = true })

  ----------------------------------------------------------------------------
  -- Use ctrl-/ to goto normal mode, so weird
  ----------------------------------------------------------------------------
  if vim.env.TMUX then
    map('t', '<C-_>', '<cmd>stopinsert<cr>', { noremap = true, silent = true })
  else
    map('t', '<C-/>', '<cmd>stopinsert<cr>', { noremap = true, silent = true })
  end

  ----------------------------------------------------------------------------
  -- Move block
  ----------------------------------------------------------------------------
  map(
    'v',
    '<c-j>',
    bind(require 'utils.mvblk', 'down'),
    { noremap = true, silent = true, desc = 'Move Selected Line Downward' }
  )
  map(
    'v',
    '<c-k>',
    bind(require 'utils.mvblk', 'up'),
    { noremap = true, silent = true, desc = 'Move Selected Line Upward' }
  )

  ----------------------------------------------------------------------------
  -- Clean search highlight and snippet highlight
  ----------------------------------------------------------------------------
  map('n', '<Esc>', function()
    vim.cmd 'nohlsearch'
    if vim.snippet then
      vim.snippet.stop()
    end
  end, { silent = true })

  ----------------------------------------------------------------------------
  -- File explorer
  ----------------------------------------------------------------------------
  map('n', '<leader>e', function()
    local open = require 'mini.files'.open
    local close = require 'mini.files'.close
    if not close() then
      open()
    end
  end, {
    desc = 'Toggle File [E]xplorer',
    noremap = true,
    silent = true,
  })

  map({ 'n', 'v' }, 'j', 'gj', { noremap = true, silent = true })
  map({ 'n', 'v' }, 'k', 'gk', { noremap = true, silent = true })

  -- Delete j and k under select mode to enable snippet
  vim.keymap.del('s', 'j')
  vim.keymap.del('s', 'k')

  map(
    { 'n' },
    '<leader>lm',
    thunk('mason.ui', 'open'),
    { noremap = true, silent = true, desc = 'Launch Lsp [M]anager' }
  )

  map(
    { 'n' },
    'U',
    vim.cmd.redo,
    { noremap = true, silent = true, desc = 'Redo' }
  )

  ----------------------------------------------------------------------------
  -- Helix style navigation
  ----------------------------------------------------------------------------
  map(
    { 'n', 'x' },
    'gh',
    '0',
    { noremap = true, silent = true, desc = 'Line start' }
  )
  map(
    { 'n', 'x' },
    'g-',
    '^',
    { noremap = true, silent = true, desc = 'Line start(non-space)' }
  )
  map(
    { 'n', 'x' },
    'gl',
    '$',
    { noremap = true, silent = true, desc = 'Line end' }
  )
  _initialized = true
end

return M

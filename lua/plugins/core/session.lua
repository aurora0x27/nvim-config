--------------------------------------------------------------------------------
-- Session manager
--------------------------------------------------------------------------------

local sandbox = require 'core.sandbox'.get_mask()
local BufferPoolManager = require 'core.bpm'

---@type LazyPluginSpec
local SessionMgr = {
  'folke/persistence.nvim',
  enabled = sandbox.session,
  dependencies = {
    'ibhagwan/fzf-lua',
  },
  event = 'BufReadPre', -- this will only start session saving when an actual file was opened
  ---@module 'persistence'
  opts = {
    dir = vim.fn.stdpath 'state' .. '/sessions/',
    need = 1,
  },
  config = function(_, opts)
    require 'persistence'.setup(opts)
    vim.api.nvim_create_autocmd('User', {
      pattern = 'PersistenceLoadPost',
      callback = function()
        if type(vim.g.BufferPoolState) == 'string' then
          BufferPoolManager.from_json(vim.g.BufferPoolState)
        end
      end,
    })
    vim.api.nvim_create_autocmd('User', {
      pattern = 'PersistenceSavePre',
      callback = function()
        vim.g.BufferPoolState = BufferPoolManager.to_json()
      end,
    })
    -- save folds and view (cursor position, etc.)
    vim.api.nvim_create_autocmd('BufWinLeave', {
      pattern = '*',
      callback = function()
        if vim.bo.buftype == '' then
          ---@diagnostic disable:param-type-mismatch
          pcall(vim.cmd, 'mkview')
        end
      end,
    })
    -- restore view on reenter buffer
    vim.api.nvim_create_autocmd('BufWinEnter', {
      pattern = '*',
      callback = function()
        if vim.bo.buftype == '' then
          ---@diagnostic disable:param-type-mismatch
          pcall(vim.cmd, 'silent! loadview')
        end
      end,
    })
  end,
}

return SessionMgr

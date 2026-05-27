--------------------------------------------------------------------------------
-- Scope manager
--------------------------------------------------------------------------------
local thunk = require 'utils.loader'.thunk
local bind = require 'utils.loader'.bind

---@type LazyPluginSpec
local ScopeMgr = {
  'tiagovla/scope.nvim',
  event = { 'BufReadPost', 'BufNewFile', 'BufReadPre' },
  config = bind(thunk('scope', 'setup'), { hooks = {} }),
}

return ScopeMgr

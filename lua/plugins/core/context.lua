--------------------------------------------------------------------------------
-- Annotions the scope for current cursor pos context by treesitter
--------------------------------------------------------------------------------
local Context = {
  'nvim-treesitter/nvim-treesitter-context',
  enabled = Profile.enable_sticky_buffer,
  event = { 'BufReadPost', 'BufNewFile' },
  opts = {
    multiwindow = true,
  },
}

return Context

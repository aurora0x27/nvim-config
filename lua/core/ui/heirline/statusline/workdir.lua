--------------------------------------------------------------------------------
-- Display current workspace dir path with a summary string
--------------------------------------------------------------------------------
local tools = require 'utils.fs'
local get_logical_cwd = tools.get_logical_cwd
local shorten_path = tools.shorten_path

local WorkDir = {
  init = function(self)
    local cwd = get_logical_cwd()
    self.cwd = vim.fn.fnamemodify(cwd, ':~')
    self.icon = require 'core.workspace'.is_restrict() and '   ' or '   '
  end,
  provider = function(self)
    if vim.o.columns < 80 then
      return ' '
    end
    if vim.o.columns < 100 then
      return self.icon
    end
    return self.icon .. shorten_path(self.cwd)
  end,
  hl = function()
    return {
      fg = 'black',
      bold = true,
    }
  end,
  update = true,
}

return WorkDir

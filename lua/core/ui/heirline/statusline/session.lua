--------------------------------------------------------------------------------
-- Display session info
--------------------------------------------------------------------------------
local SM = require 'core.persist'

local SessionInfo = {
  init = function(self)
    self.mode = vim.fn.mode()
  end,
  provider = function()
    return '@' .. (SM.current() == '_' and '*anonymous*' or SM.current()) .. ' '
  end,
  hl = function(self)
    return {
      fg = 'black',
      bg = self.mode_hl[self.mode] or 'blue',
      bold = true,
    }
  end,
  condition = function()
    return SM.get_modes().persist_mode.session
  end,
  update = true,
}

return SessionInfo

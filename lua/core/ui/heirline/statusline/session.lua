--------------------------------------------------------------------------------
-- Display session info
--------------------------------------------------------------------------------
local SM = require 'core.persist'

local SessionInfo = {
  provider = function()
    return '@' .. (SM.current() == '_' and '*anonymous*' or SM.current())
  end,
  hl = function()
    return {
      fg = 'black',
      bold = true,
    }
  end,
  condition = function()
    return SM.get_modes().persist_mode.session and vim.o.columns >= 80
  end,
  update = true,
}

return SessionInfo

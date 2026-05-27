--------------------------------------------------------------------------------
-- Tab display element
--------------------------------------------------------------------------------
local BufferPoolManager = require 'core.bpm'

local TabBlk = {
  hl = function(self)
    return self.is_active and { fg = 'teal', bold = true }
      or { fg = 'overlay2' }
  end,
  on_click = {
    minwid = function(self)
      return self.tabpage
    end,
    callback = function(_, minwid, _, button)
      if button == 'l' then
        vim.api.nvim_set_current_tabpage(minwid)
      end
    end,
    name = 'heirline_tab_switch_button',
  },
  provider = function(self)
    return ' ' .. BufferPoolManager.resolve_tabname(self.tabpage) .. ' '
  end,
}

return TabBlk

--------------------------------------------------------------------------------
-- Tab display element
--------------------------------------------------------------------------------
local TabBlk = {
  condition = function()
    return #vim.api.nvim_list_tabpages() > 1
  end,
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
    -- TODO: Use buffer pool manager to display renamed tab
    return ' ' .. self.tabnr .. ' '
  end,
}

return TabBlk

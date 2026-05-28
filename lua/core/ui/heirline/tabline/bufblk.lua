--------------------------------------------------------------------------------
-- Buffer display element
--------------------------------------------------------------------------------
local summary = require 'utils.fs'.summary
local UIIcons = require 'assets.icons'.get('ui', true)
local BufferPoolManager = require 'core.bpm'

-- Identify focus
local ActiveMark = {
  static = {
    active_icon = '┃ ',
    inactive_icon = '│ ',
  },
  provider = function(self)
    return self.is_active and self.active_icon or self.inactive_icon
  end,
  hl = function(self)
    return self.is_active and { fg = 'lavender' } or { fg = 'overlay2' }
  end,
}

local Padding = {
  provider = function(self)
    return string.rep(' ', self.buffer_padding)
  end,
}

local FileIcon = {
  init = function(self)
    self.icon, self.icon_hl =
      require 'nvim-web-devicons'.get_icon(self.filename, self.extension)
    self.icon = self.icon or '󰈙'
    self.icon_hl = self.icon_hl or 'subtext0'
  end,
  provider = function(self)
    return self.icon and (self.icon .. ' ')
  end,
  hl = function(self)
    return self.icon_hl
  end,
}

local ModifiedIcon = {
  static = {
    modified_icon = UIIcons.MiddleDot,
  },
  provider = function(self)
    return self.modified and self.modified_icon or '  '
  end,
  hl = { fg = 'teal' },
}

-- Display summarized filename
local FileName = {
  provider = function(self)
    local filename = summary(self.filename)
    return filename
  end,
  hl = function(self)
    return self.is_active and { fg = 'text_fg', bold = true, italic = true }
      or { fg = 'subtext0' }
  end,
  update = true,
}

local BufBlk = {
  static = {
    buffer_min_width = 20,
    filename_max_length = 18,
  },
  init = function(self)
    self.filepath = vim.api.nvim_buf_get_name(self.bufnr)
    self.extension = vim.fn.fnamemodify(self.filepath, ':e')
    local name = BufferPoolManager.resolve_bufname(self.bufnr)
    self.filename = name ~= '' and name or '[No Name]'
    self.modified =
      vim.api.nvim_get_option_value('modified', { buf = self.bufnr })
    local current_width = 4 + #self.filename
    local padding_needed = math.max(0, self.buffer_min_width - current_width)
    self.buffer_padding = math.floor(padding_needed / 2)
  end,
  on_click = {
    minwid = function(self)
      return self.bufnr
    end,
    callback = function(_, minwid, _, button)
      if button == 'l' then
        vim.api.nvim_set_current_buf(minwid)
      end
    end,
    name = 'heirline_buffer_switch_button',
  },
  ActiveMark,
  Padding,
  FileIcon,
  FileName,
  Padding,
  ModifiedIcon,
}

return BufBlk

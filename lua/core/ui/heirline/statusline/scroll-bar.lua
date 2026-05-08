local Styles = {
  sbar = {
    '▁▁ ',
    '▂▂ ',
    '▃▃ ',
    '▄▄ ',
    '▅▅ ',
    '▆▆ ',
    '▇▇ ',
    '██ ',
  },
  moon = {
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
    ' ',
  },
  circle = {
    ' ',
    ' ',
    '󰪞 ',
    '󰪞 ',
    '󰪟 ',
    '󰪟 ',
    '󰪠 ',
    '󰪠 ',
    '󰪡 ',
    '󰪡 ',
    '󰪢 ',
    '󰪣 ',
    '󰪣 ',
    '󰪤 ',
    '󰪤 ',
    '󰪥 ',
    '󰪥 ',
  },
}

local function get_style()
  local theme = Profile.statline_scrollbar_style
  if not Styles[theme] then
    return Styles['moon']
  else
    return Styles[theme]
  end
end

local ScrollBar = {
  static = {
    chars = get_style(),
  },
  provider = function(self)
    local chars = self.chars
    local line_ratio = vim.api.nvim_win_get_cursor(0)[1]
      / vim.api.nvim_buf_line_count(0)
    local position = math.floor(line_ratio * 100)
    local icon = chars[math.floor(line_ratio * (#chars - 1)) + 1] .. position
    if position <= 1 then
      return '↑ TOP'
    elseif
      position >= 99
      or (vim.api.nvim_buf_line_count(0) - vim.api.nvim_win_get_cursor(0)[1])
        == 1
    then
      return '↓ BOT'
    else
      return string.format('%s', icon) .. '%%'
    end
  end,
  hl = { fg = 'rosewater', bold = true },
}

return ScrollBar

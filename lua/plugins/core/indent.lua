--------------------------------------------------------------------------------
-- Indent line
--------------------------------------------------------------------------------

---@type LazyPluginSpec
local IndentLine = {
  'saghen/blink.indent',
  ---@module 'blink.indent'
  event = { 'BufReadPost', 'BufNewFile' },
  ---@type blink.indent.Config
  opts = {
    static = {
      enabled = true,
      char = '│',
    },
    scope = {
      enabled = true,
      char = '│',
      highlights = {
        'BlinkIndentOrange',
        'BlinkIndentViolet',
        'BlinkIndentBlue',
        'BlinkIndentRed',
        'BlinkIndentCyan',
        'BlinkIndentYellow',
        'BlinkIndentGreen',
      },
    },
  },
}

return IndentLine

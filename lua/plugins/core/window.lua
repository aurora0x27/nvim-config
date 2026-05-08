---@type LazySpec
local WindowManager = {
  'yorickpeterse/nvim-window',
  lazy = true,
  opts = {
    -- The characters available for hinting windows.
    chars = {
      'a',
      'b',
      'c',
      'd',
      'e',
      'f',
      'g',
      'h',
      'i',
      'j',
      'k',
      'l',
      'm',
      'n',
      'o',
      'p',
      'q',
      'r',
      's',
      't',
      'u',
      'v',
      'w',
      'x',
      'y',
      'z',
    },

    -- A group to use for overwriting the Normal highlight group in the floating
    -- window. This can be used to change the background color.
    normal_hl = 'Normal',

    -- The border style to use for the floating window.
    border = require 'assets.theme'.border,

    -- How the hints should be rendered. The possible values are:
    --
    -- - "float" (default): renders the hints using floating windows
    -- - "status": renders the hints to a string and calls `redrawstatus`,
    --   allowing you to show the hints in a status or winbar line
    render = 'float',
  },
}

return WindowManager

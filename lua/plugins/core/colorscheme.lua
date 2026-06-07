--------------------------------------------------------------------------------
-- Catppuccin Mocha scheme
--------------------------------------------------------------------------------

local transparent_mode = Profile.transparent_mode

---@type LazyPluginSpec
local ColorScheme = {
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000,
  opts = {
    integrations = {
      alpha = true,
      noice = true,
      cmp = true,
      gitsigns = true,
      mason = true,
      nvimtree = true,
      treesitter = true,
      notify = false,
    },

    -- flavour = 'macchiato', -- latte, frappe, macchiato, mocha
    flavour = 'mocha', -- latte, frappe, macchiato, mocha

    background = { -- :h background
      light = 'latte',
      dark = 'mocha',
    },

    transparent_background = transparent_mode, -- disables setting the background color.
    show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
    term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)

    dim_inactive = {
      enabled = false, -- dims the background color of inactive window
      shade = 'dark',
      percentage = 0.15, -- percentage of the shade to apply to the inactive window
    },

    float = {
      transparent = transparent_mode,
    },

    no_italic = false, -- Force no italic
    no_bold = false, -- Force no bold
    no_underline = false, -- Force no underline
    styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
      comments = { 'italic' }, -- Change the style of comments
      conditionals = { 'italic' },
      loops = {},
      functions = {},
      keywords = {},
      strings = {},
      variables = {},
      numbers = {},
      booleans = {},
      properties = {},
      types = {},
      operators = {},
      -- miscs = {}, -- Uncomment to turn off hard-coded styles
    },
    color_overrides = {},
    custom_highlights = {},
    default_integrations = true,
    highlight_overrides = {
      mocha = function(mocha)
        local replace = {}
        if transparent_mode then
          replace.LineNr = { fg = mocha.overlay2 }
          replace.BufferLineBufferVisible = { fg = mocha.overlay2 }
          replace.BufferLineDuplicateVisible = { fg = mocha.overlay2 }
          replace.BufferLineDuplicate = { fg = mocha.overlay2 }
          replace.NoiceCmdlinePopupBorder = { fg = mocha.teal }
        else
          replace.NormalFloat = { bg = mocha.base }
          replace.FloatBorder = { bg = mocha.base }
          replace.NoiceCmdlinePopupBorder = { fg = mocha.teal }
        end
        replace.NeogitFloatBorder = { fg = mocha.blue }
        replace.NeogitDiffAddInline = { bg = mocha.green, fg = mocha.crust }
        replace.NeogitDiffDeleteInline = { bg = mocha.red, fg = mocha.crust }
        return replace
      end,
    },
  },
  config = function(_, opts)
    require 'catppuccin'.setup(opts)

    -- setup must be called before loading
    vim.cmd.colorscheme 'catppuccin'
  end,
}

return ColorScheme

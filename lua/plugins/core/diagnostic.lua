--------------------------------------------------------------------------------
-- Enhanced diagnostic display
--------------------------------------------------------------------------------

local Diagnose = require 'core.diagnostic'

local lvl

---resolve diagnostics level
---@param s string
---@return integer
local function resolve_lvl(s)
  if lvl then
    return lvl
  end
  if not s then
    return vim.diagnostic.severity.HINT
  end
  s = s:upper()
  lvl = vim.diagnostic.severity[s] or vim.diagnostic.severity.HINT
  return lvl
end

---@type LazySpec
local TinyInlineDiag = {
  'rachartier/tiny-inline-diagnostic.nvim',
  event = { 'BufReadPost', 'BufNewFile' },
  enabled = Diagnose.get_mode() == Diagnose.MODE.pretty,
  opts = {
    preset = 'simple',
    transparent_bg = Profile.transparent_mode,
    options = {
      multilines = {
        enabled = true,
      },
      show_source = {
        enabled = true,
        if_many = true,
      },
      add_messages = {
        display_count = true,
      },
      overflow = {
        mode = 'wrap',
        padding = 2,
      },
      set_arrow_to_diag_color = false,
      use_icons_from_diagnostic = true,
      show_all_diags_on_cursorline = false,
      severity = vim.tbl_filter(function(level)
        return level <= resolve_lvl(Profile.diagnose_level)
      end, {
        vim.diagnostic.severity.ERROR,
        vim.diagnostic.severity.WARN,
        vim.diagnostic.severity.INFO,
        vim.diagnostic.severity.HINT,
      }),
    },
    disabled_ft = {
      'alpha',
      'checkhealth',
      'dap-repl',
      'diff',
      'help',
      'log',
      'notify',
      'NvimTree',
      'Outline',
      'qf',
      'TelescopePrompt',
      'toggleterm',
      'undotree',
      'vimwiki',
    },
  },
}

return TinyInlineDiag

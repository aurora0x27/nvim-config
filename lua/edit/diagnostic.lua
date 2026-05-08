--------------------------------------------------------------------------------
-- Diagnostics config
--------------------------------------------------------------------------------

local M = {}

local IconDiag = require 'assets.icons'.get('diagnostics', true)

local RawIconSpec = {
  [vim.diagnostic.severity.ERROR] = {
    icon = IconDiag.Error,
    hl = 'DiagnosticError',
  },
  [vim.diagnostic.severity.WARN] = {
    icon = IconDiag.Warning,
    hl = 'DiagnosticWarn',
  },
  [vim.diagnostic.severity.INFO] = {
    icon = IconDiag.Information,
    hl = 'DiagnosticInfo',
  },
  [vim.diagnostic.severity.HINT] = {
    -- we use info icon here because hint icon is too small
    icon = IconDiag.Information,
    hl = 'DiagnosticHint',
  },
}

local thunk = require 'utils.loader'.thunk

local IconTable = (function()
  local ret = {}
  for severity, spec in pairs(RawIconSpec) do
    ret[severity] = spec.icon
  end
  return ret
end)()

local get_mode = require 'core.diagnostic'.get_mode
local DIAGNOSE_MODE = require 'core.diagnostic'.MODE

function M.setup()
  local with_underline = Profile.diagnose_with_fancy_underline

  -- diagnostic info
  vim.diagnostic.config {
    virtual_text = get_mode() == DIAGNOSE_MODE.inline,
    virtual_lines = get_mode() == DIAGNOSE_MODE.detailed,
    underline = with_underline and {
      severity = { min = vim.diagnostic.severity.WARN },
    } or false,
    signs = {
      text = IconTable,
    },
    update_in_insert = false,
    float = {
      border = 'rounded',
      header = '',
      source = true,
      prefix = function(diag)
        local map = RawIconSpec
        local spec = map[diag.severity]
        return spec.icon, spec.hl
      end,
    },
  }

  if with_underline then
    --- make underline hl by base
    ---@param name string
    ---@param base string
    local function make_underline(name, base)
      local hl = vim.api.nvim_get_hl(0, { name = base })
      vim.api.nvim_set_hl(0, name, {
        undercurl = true,
        sp = hl.fg,
      })
    end
    make_underline('DiagnosticUnderlineError', 'DiagnosticError')
    make_underline('DiagnosticUnderlineWarn', 'DiagnosticWarn')
    make_underline('DiagnosticUnderlineInfo', 'DiagnosticInfo')
    make_underline('DiagnosticUnderlineHint', 'DiagnosticHint')
  end

  -- Hover diagnostics
  vim.keymap.set(
    'n',
    '<leader>ld',
    thunk('vim.diagnostic', 'open_float'),
    { desc = 'Hover [D]iagnostics' }
  )
end

function M.get_icon_map()
  return RawIconSpec
end

return M

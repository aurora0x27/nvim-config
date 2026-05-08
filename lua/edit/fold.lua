--------------------------------------------------------------------------------
-- Fold Text Style
--------------------------------------------------------------------------------
local M = {}

-- style
-- foo { ... }   󰁂 [xx lines folded]
function M.custom_foldtext()
  local blnum = vim.v.foldstart
  local bline = vim.fn.getline(blnum):gsub('\t', string.rep(' ', vim.o.tabstop))

  local elnum = vim.v.foldend
  local eline = vim.fn.getline(elnum):gsub('\t', string.rep(' ', vim.o.tabstop))

  local result = {}
  table.insert(result, { bline, 'WinBar' })
  table.insert(result, { ' ... ', 'Delimiter' })
  table.insert(result, { vim.trim(eline), 'WinBar' })
  table.insert(result, {
    '   󰁂 [' .. (vim.v.foldend - vim.v.foldstart) .. ' lines folded]',
    'CustomFold',
  })
  return result
end

function M.setup()
  -- Fold hint
  local mocha = require 'catppuccin.palettes'.get_palette 'mocha'
  vim.api.nvim_set_hl(
    0,
    'CustomFold',
    { fg = mocha.teal, bold = true, italic = true }
  )

  vim.o.foldlevel = 99
  vim.o.foldlevelstart = 99
  vim.o.foldcolumn = '1'
  if not Profile.use_ufo_as_fold_provider then
    vim.o.foldtext = [[v:lua.require'edit.fold'.custom_foldtext()]]
    vim.o.foldmethod = 'expr'
    vim.o.foldexpr = [[v:lua.vim.treesitter.foldexpr()]]
  end
end

return M

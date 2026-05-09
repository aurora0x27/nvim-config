vim.bo.shiftwidth = 2
vim.bo.tabstop = 2
vim.bo.softtabstop = 2
if vim.b.did_ftplugin then
  vim.api.nvim_set_hl(0, '@keyword.operator.lua', { link = 'Operator' })
end

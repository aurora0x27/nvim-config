if vim.b.did_ftplugin then
  return
end

vim.keymap.set('n', 'K', function()
  vim.cmd('Man ' .. vim.fn.expand '<cword>')
end, { silent = true, buf = 0, desc = 'Man: Jump to man page of current word' })

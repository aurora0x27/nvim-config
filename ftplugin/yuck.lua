if vim.b.did_ftplugin then
  return
end

vim.cmd 'runtime! ftplugin/lisp.vim'

vim.bo.commentstring = '; %s'
vim.bo.comments = ':;'

vim.bo.lispwords = 'defwidget,defwindow,defpoll,deflisten,defvar,defun,let,let*'

vim.bo.lisp = true

vim.bo.expandtab = true
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
  .. 'setlocal commentstring< comments< lispwords< lisp< expandtab< shiftwidth< softtabstop<'

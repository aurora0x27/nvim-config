local TermApp = {}

local select = require('utils.loader').select

function TermApp.apply()
    vim.keymap.set(
        { 'n', 't' },
        '<leader>tg',
        select('modules.lazygit', 'toggle'),
        { noremap = true, silent = true, desc = '[T]oggle Lazy[G]it' }
    )
    vim.keymap.set(
        { 'n', 't' },
        '<leader>tb',
        select('modules.yazi', 'toggle'),
        { noremap = true, silent = true, desc = '[T]oggle File [B]rowser' }
    )
end

return TermApp

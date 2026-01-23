local TermApp = {}

local select = require('utils.loader').select

function TermApp.apply()
    vim.api.nvim_create_user_command('Lazygit', select('modules.lazygit', 'toggle'), {})
    vim.api.nvim_create_user_command('Yazi', select('modules.yazi', 'toggle'), {})
end

return TermApp

-- Remote clipboard support based on osc52

local SSHMode = {
    on = false,
    old_clipboard = vim.g.clipboard,
    auto_enable = true,
}

local switch_mode = function()
    if SSHMode.on then
        vim.g.clipboard = SSHMode.old_clipboard
        SSHMode.on = false
        vim.notify('Clipboard ssh mode OFF', vim.log.levels.INFO)
    else
        vim.g.clipboard = {
            name = 'OSC 52',
            copy = {
                ['+'] = require('vim.ui.clipboard.osc52').copy '+',
                ['*'] = require('vim.ui.clipboard.osc52').copy '*',
            },
            paste = {
                ['+'] = require('vim.ui.clipboard.osc52').paste '+',
                ['*'] = require('vim.ui.clipboard.osc52').paste '*',
            },
            cache_enabled = false,
        }
        SSHMode.on = true
        vim.notify('Clipboard ssh mode ON', vim.log.levels.INFO)
    end
end

SSHMode.apply = function()
    vim.api.nvim_create_user_command('ClipboardSshModeSwitch', function()
        switch_mode()
    end, { desc = 'Enable or disable Clipboard Ssh Mode' })

    vim.api.nvim_create_user_command('ClipboardSshModeInfo', function()
        local message = ''
        if SSHMode.on then
            message = 'Clipboard ssh mode ON'
        else
            message = 'Clipboard ssh mode OFF'
        end
        vim.notify(message, vim.log.levels.INFO)
    end, { desc = 'Check ssh mode status' })

    -- Automatically enable ssh mode
    if SSHMode.auto_enable and SSHMode.on == false and vim.fn.exists '$SSH_TTY' == 1 then
        switch_mode()
    end
end

return SSHMode

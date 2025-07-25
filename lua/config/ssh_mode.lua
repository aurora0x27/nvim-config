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
        if vim.fn.has 'wsl' == 1 then
            ---@diagnostic disable-next-line: param-type-mismatch
            local script_folder = vim.fs.joinpath(vim.fn.stdpath 'config', 'scripts')

            vim.g.clipboard = {
                name = 'WslClipboard',
                copy = {
                    -- WARN: clip.exe might produce garbled text under certain conditions
                    -- ['+'] = 'clip.exe',
                    -- ['*'] = 'clip.exe',
                    ['+'] = 'win32yank.exe -i',
                    ['*'] = 'win32yank.exe -i',
                },
                paste = {
                    -- -- ['+'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
                    -- -- ['*'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
                    -- ['+'] = 'win32yank.exe --1f',
                    -- ['*'] = 'win32yank.exe --1f',
                    ['+'] = vim.fs.joinpath(script_folder, 'wsl-paste.sh'),
                    ['*'] = vim.fs.joinpath(script_folder, 'wsl-paste.sh'),
                },
                cache_enabled = true,
            }
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
        end
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

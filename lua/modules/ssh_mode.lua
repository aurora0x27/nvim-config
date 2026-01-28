-- Remote clipboard support based on osc52

local M = {}

local log = require 'utils.tools'
local on = false
local old_clipboard = vim.g.clipboard
local auto_enable = true

local switch_mode = function()
    if on then
        vim.g.clipboard = old_clipboard
        on = false
        log.info('Clipboard ssh mode OFF', { title = 'SSH Mode' })
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
        on = true
        log.info('Clipboard ssh mode ON', { title = 'SSH Mode' })
    end
end

M.setup = function()
    vim.api.nvim_create_user_command('ClipboardSshModeSwitch', function()
        switch_mode()
    end, { desc = 'Enable or disable Clipboard Ssh Mode' })

    vim.api.nvim_create_user_command('ClipboardSshModeInfo', function()
        local message = ''
        if on then
            message = 'Clipboard ssh mode ON'
        else
            message = 'Clipboard ssh mode OFF'
        end
        log.info(message, { title = 'SSH Mode' })
    end, { desc = 'Check ssh mode status' })

    -- Automatically enable ssh mode
    if auto_enable and on == false and vim.fn.exists '$SSH_TTY' == 1 then
        switch_mode()
    end
end

return M

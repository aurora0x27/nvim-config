-- Diagnostics config
return {
    apply = function()
        local mocha = require('catppuccin.palettes').get_palette 'mocha'
        for type, icon in pairs {
            Error = ' ',
            Warn = ' ',
            Info = ' ',
            Hint = ' ',
        } do
            local hl = 'DiagnosticSign' .. type
            vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = '' })
        end

        vim.opt.signcolumn = 'yes:2'

        vim.diagnostic.config {
            signs = { priority = 5 },
            virtual_text = false,
            underline = true,
        }

        vim.api.nvim_set_hl(0, 'DiagnosticSignError', { fg = mocha.red })
        vim.api.nvim_set_hl(0, 'DiagnosticSignWarn', { fg = mocha.yellow })

        -- diagnostic info
        vim.diagnostic.config {
            virtual_text = false,
            virtual_lines = {
                only_current_line = true,
                -- severity = { min = vim.diagnostic.severity.WARN }
            },
            underline = true,
            signs = true,
            update_in_insert = false,
            float = {
                border = 'rounded',
                header = '',
                source = true,
                -- prefix = function(diag)
                --   local icons = require("core.icons").diagnostics
                --   return icons[diag.severity] .. " "
                -- end
            },
        }

        -- auto update diagnostic info
        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            callback = function()
                vim.diagnostic.show(nil, 0, nil, { virtual_lines = { only_current_line = true } })
            end,
        })

        -- Hover diagnostics
        vim.keymap.set('n', '<Leader>ld', function()
            vim.diagnostic.open_float()
        end, { desc = 'Hover diagnostics' })
    end,
}

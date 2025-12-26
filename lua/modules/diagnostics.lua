-- Diagnostics config

local DiagnosticConfig = {}

local IconTable = {
    [vim.diagnostic.severity.ERROR] = ' ',
    [vim.diagnostic.severity.WARN] = ' ',
    [vim.diagnostic.severity.INFO] = ' ',
    [vim.diagnostic.severity.HINT] = ' ',
}

DiagnosticConfig.apply = function()
    -- diagnostic info
    vim.diagnostic.config {
        virtual_text = false,
        virtual_lines = {
            only_current_line = true,
            -- severity = { min = vim.diagnostic.severity.WARN }
        },
        underline = true,
        signs = {
            text = IconTable,
        },
        update_in_insert = false,
        float = {
            border = 'rounded',
            header = '',
            source = true,
            prefix = function(diag)
                local map = require('utils.assets').DiagnosticIconMap
                local icon, hl = unpack(map[diag.severity])
                return icon .. ' ', hl
            end,
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
    end, { desc = 'Hover [D]iagnostics' })
end

return DiagnosticConfig

-- Diagnostics config

local Diagnostic = {}

local IconTable = {
    [vim.diagnostic.severity.ERROR] = ' ',
    [vim.diagnostic.severity.WARN] = ' ',
    [vim.diagnostic.severity.INFO] = ' ',
    [vim.diagnostic.severity.HINT] = ' ',
}

---@type vim.diagnostic.Opts
local DiagnosticsConfig = {
    virtual_text = vim.g.diag_inline,
    virtual_lines = not vim.g.diag_inline,
    underline = false,
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

Diagnostic.apply = function()
    -- diagnostic info
    vim.diagnostic.config(DiagnosticsConfig)

    -- auto update diagnostic info
    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        callback = function()
            vim.diagnostic.show(nil, 0, nil)
        end,
    })

    -- Hover diagnostics
    vim.keymap.set('n', '<Leader>ld', function()
        vim.diagnostic.open_float()
    end, { desc = 'Hover [D]iagnostics' })
end

return Diagnostic

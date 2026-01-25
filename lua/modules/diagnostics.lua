-- Diagnostics config

local Diagnostic = {}

local RawIconSpec = require('utils.assets').RawDiagnosticSpec

local select = require('utils.loader').select

local IconTable = (function()
    local ret = {}
    for severity, spec in pairs(RawIconSpec) do
        ret[severity] = spec.icon
    end
    return ret
end)()

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
            local map = RawIconSpec
            local spec = map[diag.severity]
            return spec.icon .. ' ', spec.hl
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
    vim.keymap.set('n', '<Leader>ld', select('vim.diagnostics', 'open_float'), { desc = 'Hover [D]iagnostics' })
end

return Diagnostic

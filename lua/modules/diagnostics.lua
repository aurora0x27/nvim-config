--------------------------------------------------------------------------------
-- Diagnostics config
--------------------------------------------------------------------------------

local M = {}

local RawIconSpec = {
    [vim.diagnostic.severity.ERROR] = {
        icon = ' ',
        hl = 'DiagnosticError',
    },
    [vim.diagnostic.severity.WARN] = {
        icon = ' ',
        hl = 'DiagnosticWarn',
    },
    [vim.diagnostic.severity.INFO] = {
        icon = ' ',
        hl = 'DiagnosticInfo',
    },
    [vim.diagnostic.severity.HINT] = {
        icon = '󰌵 ',
        hl = 'DiagnosticHint',
    },
}

local thunk = require('utils.loader').thunk

local IconTable = (function()
    local ret = {}
    for severity, spec in pairs(RawIconSpec) do
        ret[severity] = spec.icon
    end
    return ret
end)()

---@type vim.diagnostic.Opts
local DiagnosticsConfig = {
    virtual_text = Profile.diagnose_inline,
    virtual_lines = not Profile.diagnose_inline,
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

function M.setup()
    -- diagnostic info
    vim.diagnostic.config(DiagnosticsConfig)

    -- Hover diagnostics
    vim.keymap.set(
        'n',
        '<leader>ld',
        thunk('vim.diagnostic', 'open_float'),
        { desc = 'Hover [D]iagnostics' }
    )
end

function M.get_icon_map()
    return RawIconSpec
end

return M

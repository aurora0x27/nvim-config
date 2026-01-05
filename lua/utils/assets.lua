local M = {}

M.RawDiagnosticSpec = {
    [vim.diagnostic.severity.ERROR] = {
        icon = '󰅚 ',
        hl = 'DiagnosticError',
    },
    [vim.diagnostic.severity.WARN] = {
        icon = '󰀪 ',
        hl = 'DiagnosticWarn',
    },
    [vim.diagnostic.severity.INFO] = {
        icon = '󰋽 ',
        hl = 'DiagnosticInfo',
    },
    [vim.diagnostic.severity.HINT] = {
        icon = '󰌶 ',
        hl = 'DiagnosticHint',
    },
}

-- TODO: replace all the hard coded style
-- Border style of floating windows
M.border = 'rounded'

return M

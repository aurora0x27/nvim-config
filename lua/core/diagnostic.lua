--------------------------------------------------------------------------------
-- Diagnostic options
--
-- Options:
--   * mode       'inline'|'pretty'|'detailed'
--------------------------------------------------------------------------------
local M = {}

---@enum DiagnosticMode
local DIAGNOSE_MODE = {
    detailed = 1,
    inline = 2,
    pretty = 3,
}

M.MODE = DIAGNOSE_MODE

---@param s string
---@return integer
local function resolve_mode(s)
    local mode = DIAGNOSE_MODE[s]
    if mode then
        return mode
    end
    vim.notify(
        '`' .. s .. '` is not valid diagnose mode, fallback to `inline`',
        vim.log.levels.ERROR,
        { title = 'Diagnose' }
    )
    return DIAGNOSE_MODE.inline
end

---@type integer
local CurrMode

function M.get_mode()
    if not CurrMode then
        CurrMode = resolve_mode(Profile.diagnose_mode)
    end
    return CurrMode
end

return M

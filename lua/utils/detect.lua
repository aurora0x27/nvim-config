local M = {}

---@return boolean
function M.is_unix()
    return vim.fn.has 'unix' == 1
end

---@return boolean
function M.is_linux()
    return vim.fn.has 'linux' == 1
end

---@return boolean
function M.is_macos()
    return vim.fn.has 'mac' == 1
end

---@return boolean
function M.is_windows()
    return vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1
end

return M

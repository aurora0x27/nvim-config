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

---@param cmd string
---@return boolean
function M.is_executable(cmd)
  return vim.fn.executable(cmd) == 1
end

---@param bufnr integer
---@return boolean
function M.is_bigfile(bufnr)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  return line_count > Profile.bigfile_size_line
    or vim.api.nvim_buf_get_offset(bufnr, line_count)
      > Profile.bigfile_size_byte
end

return M

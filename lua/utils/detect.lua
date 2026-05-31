local M = {}

---@return boolean
function M.is_unix()
  return jit.os == 'POSIX' or jit.os == 'BSD' or jit.os == 'OSX'
end

---@return boolean
function M.is_linux()
  return jit.os == 'Linux'
end

---@return boolean
function M.is_macos()
  return jit.os == 'OSX'
end

---@return boolean
function M.is_windows()
  return jit.os == 'Windows'
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

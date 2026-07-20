--------------------------------------------------------------------------------
-- Strx -- expaned lua string utils
--------------------------------------------------------------------------------
local M = {}

---@param s string
---@param threshold? integer
---@param prefix? integer
---@param suffix? integer
function M.summary(s, threshold, prefix, suffix)
  threshold = threshold or 30
  prefix = prefix or 10
  suffix = suffix or 10
  assert(prefix + suffix <= threshold)
  if #s > threshold then
    return s:sub(1, prefix) .. '…' .. s:sub(-suffix)
  end
  return s
end

return M

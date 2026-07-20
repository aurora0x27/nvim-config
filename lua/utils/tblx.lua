--------------------------------------------------------------------------------
-- Tblx -- expanded lua table utils
--------------------------------------------------------------------------------
local M = {}

---@generic K, V
---@param tbl table<K, V>
---@param comp? fun(a: K, b: K): boolean
---@return fun(): K, V
function M.sorted_pairs(tbl, comp)
  local keys = {}
  for k in pairs(tbl) do
    keys[#keys + 1] = k
  end
  table.sort(keys, comp)
  local i = 0
  return function()
    i = i + 1
    local k = keys[i]
    if k ~= nil then
      return k, tbl[k]
    end
  end
end

return M

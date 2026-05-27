--------------------------------------------------------------------------------
-- Resolve names for buffer
--------------------------------------------------------------------------------
local M = {}

local Sep = package.config:sub(1, 1) -- path separator

---@param map table<integer, string>
---@return table<integer, string>
function M.shortest_unique_suffix(map)
  -- TODO: Trie optimize?
  local ret = {}

  ---@type table<integer, string[]>
  local split_paths = {}

  for id, path in pairs(map) do
    --- filter empty buffer, they don't be calculated
    if path == '' then
      ret[id] = ''
    else
      local parts = vim.split(path, Sep, { plain = true })
      if parts[1] == '' then
        table.remove(parts, 1)
      end
      split_paths[id] = parts
    end
  end

  for id, parts in pairs(split_paths) do
    local depth = 1
    local resolved = parts[#parts] or ''

    while depth <= #parts do
      local suffix =
        table.concat(vim.list_slice(parts, #parts - depth + 1, #parts), Sep)
      local unique = true

      for other_id, other_parts in pairs(split_paths) do
        if other_id ~= id then
          local other_depth = math.min(depth, #other_parts)
          local other_suffix = table.concat(
            vim.list_slice(
              other_parts,
              #other_parts - other_depth + 1,
              #other_parts
            ),
            Sep
          )

          if suffix == other_suffix then
            unique = false
            break
          end
        end
      end

      resolved = suffix

      if unique then
        break
      end

      depth = depth + 1
    end

    ret[id] = resolved
  end

  return ret
end

return M

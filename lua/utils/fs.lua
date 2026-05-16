local M = {}
local unpack = table.unpack or unpack

--- `/foo/bar/baz/aaa/bbb/ccc` -> `/foo/…/bbb/ccc`
---@param dir string path to resolve
---@param lvl? integer max levels, defaults `2`
---@param sep? string separator, defaults `…`
---@return string
function M.shorten_path(dir, lvl, sep)
  lvl = lvl or 2
  sep = sep or '…'
  local parts = {}
  for p in string.gmatch(dir, '[^/]+') do
    table.insert(parts, p)
  end

  local total_parts = #parts
  if total_parts > (1 + lvl) then
    -- need compact
    local is_tilde = string.sub(dir, 1, 1) == '~'
    local prefix = is_tilde and '~' or ('/' .. parts[1])
    local last_parts = { unpack(parts, total_parts - lvl + 1, total_parts) }
    return prefix .. '/' .. sep .. '/' .. table.concat(last_parts, '/')
  else
    -- too short
    return dir
  end
end

-- Resolve cwd
--
-- Process path like /Volumes/Workspace -> ~/Workspace
-- vim.fn.getcwd(0) always returns physical path `/Volumes/Workspace`
-- but we expect `~/Workspace`
function M.get_logical_cwd()
  local physical_cwd = vim.fn.getcwd(0)
  local logical_cwd = os.getenv('PWD')

  if logical_cwd and logical_cwd ~= '' then
    if vim.fn.resolve(logical_cwd) == physical_cwd then
      return vim.fn.fnamemodify(logical_cwd, ':~')
    end
  end

  return vim.fn.fnamemodify(physical_cwd, ':~')
end

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

local M = {}

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

  local prefix
  local remaining_parts
  if vim.startswith(dir, '~') then
    prefix = '~'
    remaining_parts = { unpack(parts, lvl) }
  else
    prefix = '/' .. parts[1]
    remaining_parts = parts
  end

  if #remaining_parts > lvl then
    local last2 =
      { unpack(remaining_parts, #remaining_parts - 1, #remaining_parts) }
    return prefix .. '/' .. sep .. '/' .. table.concat(last2, '/')
  else
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

return M

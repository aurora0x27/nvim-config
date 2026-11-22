--------------------------------------------------------------------------------
-- Strx -- expaned lua string utils
--------------------------------------------------------------------------------
local M = {}

local u8 = require 'utils.utf8'

--- Display width of a string, tolerating embedded NUL bytes.
--- `strdisplaywidth()` rejects Lua strings containing NUL, so measure them
--- with a printable placeholder instead.
---@param s string
---@return integer
local function display_width(s)
  if s:find('\0', 1, true) then
    s = s:gsub('%z', '\1')
  end
  return vim.fn.strdisplaywidth(s)
end

--- Split a string into displayable UTF-8 chunks, tolerating invalid bytes.
---@param s string
---@return string[]
local function to_chars(s)
  local chars = {}
  for _, c in u8.iter_lossy(s) do
    chars[#chars + 1] = c
  end
  return chars
end

--- Take chunks from either end until the display width limit is reached.
---@param chars string[]
---@param limit integer
---@param from_end? boolean
---@param base_col? integer column where the result will start
---@return string
local function take_cells(chars, limit, from_end, base_col)
  base_col = base_col or 0
  local pad = base_col > 0 and string.rep(' ', base_col) or ''
  local out = {}
  local i = from_end and #chars or 1
  local step = from_end and -1 or 1

  while i >= 1 and i <= #chars do
    local candidate
    if from_end then
      candidate = chars[i] .. table.concat(out)
    else
      candidate = table.concat(out) .. chars[i]
    end

    if display_width(pad .. candidate) - base_col > limit then
      break
    end

    if from_end then
      table.insert(out, 1, chars[i])
    else
      out[#out + 1] = chars[i]
    end

    i = i + step
  end

  return table.concat(out)
end

--- Shorten a string to a maximum display width by keeping its head and tail.
--- The result may be one cell wider than `threshold` because of the ellipsis.
---@param s string
---@param threshold? integer max display width
---@param prefix? integer display width kept at head
---@param suffix? integer display width kept at tail
---@return string
function M.summary(s, threshold, prefix, suffix)
  threshold = threshold or 30
  prefix = prefix or 10
  suffix = suffix or 10
  assert(prefix + suffix <= threshold)

  if display_width(s) <= threshold then
    return s
  end

  local chars = to_chars(s)
  local head = take_cells(chars, prefix, false)
  local tail = take_cells(chars, suffix, true, display_width(head) + 1)

  return head .. '…' .. tail
end

--- Truncate a string to a maximum display width, appending an ellipsis.
--- The result is never wider than `width`.
---@param s string
---@param width integer
---@return string
function M.truncate(s, width)
  if display_width(s) <= width then
    return s
  end

  local limit = width - 1
  if limit < 0 then
    return ''
  end

  local out = {}

  for _, c in u8.iter_lossy(s) do
    local candidate = table.concat(out) .. c

    if display_width(candidate) > limit then
      break
    end

    out[#out + 1] = c
  end

  return table.concat(out) .. '…'
end

--- Right-pad a string to a display width.
---@param s string
---@param width integer
---@return string
function M.pad(s, width)
  local n = width - display_width(s)

  if n <= 0 then
    return s
  end

  return s .. string.rep(' ', n)
end

return M

--------------------------------------------------------------------------------
-- UTF-8 module
--------------------------------------------------------------------------------
local M = {}

local sprintf = string.format

---@param s string
---@param off integer 1-based byte offset
---@return boolean ok, integer? len
function M.is_valid_start_at(s, off)
  local byte = string.byte
  local slen = #s

  if off < 1 or off > slen then
    return false
  end

  local len_left = slen - off + 1

  local b1 = byte(s, off)
  local len

  if b1 <= 0x7F then
    len = 1
  elseif b1 >= 0xC2 and b1 <= 0xDF then
    len = 2
    if len_left < len then
      return false
    end
  elseif b1 >= 0xE0 and b1 <= 0xEF then
    len = 3
    if len_left < len then
      return false
    end

    local b2 = byte(s, off + 1)

    if b1 == 0xE0 and b2 < 0xA0 then
      return false
    end

    if b1 == 0xED and b2 > 0x9F then
      return false
    end
  elseif b1 >= 0xF0 and b1 <= 0xF4 then
    len = 4
    if len_left < len then
      return false
    end

    local b2 = byte(s, off + 1)

    if b1 == 0xF0 and b2 < 0x90 then
      return false
    end

    if b1 == 0xF4 and b2 > 0x8F then
      return false
    end
  else
    return false
  end

  for i = 1, len - 1 do
    local b = byte(s, off + i)

    if b < 0x80 or b > 0xBF then
      return false
    end
  end

  return true, len
end

---@param s string
---@return boolean
function M.is_valid_char(s)
  local ret, len = M.is_valid_start_at(s, 1)
  return ret and len == #s
end

---@param s string
---@param off? integer 1-based byte offset
---@return boolean ok, integer? broken_offset
function M.validate(s, off)
  local pos = off or 1
  if pos < 1 or pos > #s + 1 then
    return false, pos
  end
  while pos <= #s do
    local ok, len = M.is_valid_start_at(s, pos)
    if not ok then
      return false, pos
    end
    pos = pos + len
  end
  local ok = pos == #s + 1
  return ok, not ok and pos or nil
end

--- Generate a iterator for iterating a utf-8 string
---@param s string
---@return fun():integer?, string?
function M.iter(s)
  local pos = 1
  return function()
    if pos > #s then
      return nil
    end
    local ok, len = M.is_valid_start_at(s, pos)
    if not ok then
      error(sprintf('invalid UTF-8 string at byte offset %d', pos), 2)
    end
    local off = pos
    local u8_char = string.sub(s, pos, pos + len - 1)
    pos = pos + len
    return off, u8_char
  end
end

--- Lenient iterator: mirrors the historical punc-conv decoder.
--- Invalid/truncated sequences are yielded verbatim; never errors.
---@param s string
---@return fun():integer?, string?
function M.iter_lossy(s)
  local pos = 1
  return function()
    if pos > #s then
      return nil
    end

    local b = string.byte(s, pos)
    local len = 1
    if b >= 0xF0 then
      len = 4
    elseif b >= 0xE0 then
      len = 3
    elseif b >= 0xC0 then
      len = 2
    end

    local off = pos
    local c = string.sub(s, pos, pos + len - 1)
    pos = pos + len
    return off, c
  end
end

return M

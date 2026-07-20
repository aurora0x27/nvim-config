--------------------------------------------------------------------------------
-- Mangling -- generate stable signature for flat lua tables
--
-- Treats flat table as *args and **kwargs, integer indexes is searialized
-- before k-v pairs.
--
-- Syntax:
--
-- <section> ::= <len><payload>
--
-- <payload> ::=
--     s:<escaped-string>
--   | n:<number>
--   | b:t
--   | b:f
--   | <key>@<payload>
--
-- <key> ::= escaped-string
--
-- e.g.
-- { 1, 2, 3, foo = 'bar', xxx = 114514, yyy = true }
-- => '3n:13n:23n:39foo@s:bar7yyy@b:t12xxx@n:114514'
--------------------------------------------------------------------------------
local M = {}

local sprintf = string.format

-- Characters that may appear in filenames without escaping.
-- Delimiters such as '@', ':', '%' are intentionally excluded.
-- '@' : key/value separator
-- ':' : type separator
-- '%' : escape introducer
local SAFE_CHARSET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  .. 'abcdefghijklmnopqrstuvwxyz'
  .. '0123456789'
  .. '._-'

--- Escape arbitrary string into a filename-safe representation.
---
--- Safe characters:
---   [A-Za-z0-9._-]
---
--- All other bytes are encoded as `%HH` (uppercase hexadecimal).
--- The encoding is byte-oriented (UTF-8 safe).
---
---@param s string
---@return string
local function mangle_str(s)
  return (
    s:gsub('.', function(c)
      if SAFE_CHARSET:find(c, 1, true) then
        return c
      end

      return string.format('%%%02X', string.byte(c))
    end)
  )
end

---@alias MangleValue string|boolean|number

---@class MangleObject
---@field [integer] MangleValue
---@field [string] MangleValue

---@param v MangleValue
---@return string, string
local function mangle_val(v)
  local vstr
  local vtype
  local ty_v = type(v)
  if ty_v == 'string' then
    vstr = mangle_str(v)
    vtype = 's'
  elseif ty_v == 'boolean' then
    vtype = 'b'
    vstr = v and '1' or '0'
  elseif ty_v == 'number' then
    vtype = 'n'
    vstr = tostring(v)
  else
    error('`v` should have type `string|boolean|number`')
  end
  return vstr, vtype
end

---@param tbl MangleObject
---@return string
function M.encode(tbl)
  local ty = type(tbl)
  assert(ty == 'table')
  local Str = ''

  for _, v in ipairs(tbl) do
    local vstr, vtype = mangle_val(v)
    local size = #vstr + #vtype + 1
    Str = Str .. sprintf('%d%s:%s', size, vtype, vstr)
  end

  local keys = vim.tbl_filter(function(v)
    return type(v) == 'string'
  end, vim.tbl_keys(tbl))

  table.sort(keys)

  for _, k in ipairs(keys) do
    local v = tbl[k]
    local kstr = mangle_str(k)
    local vstr, vtype = mangle_val(v)
    local size = #kstr + #vstr + #vtype + 2
    Str = Str .. sprintf('%d%s@%s:%s', size, kstr, vtype, vstr)
  end
  return Str
end

--- Decode a string produced by `mangle_str`.
---
---@param s string
---@return string
local function unmangle_str(s)
  return (
    s:gsub('%%(%x%x)', function(hex)
      return string.char(tonumber(hex, 16))
    end)
  )
end

--- Decode a string produced by `mangle`.
---
---@param s string
---@return MangleObject
function M.decode(s)
  if s == '' then
    return {}
  end

  local tbl = {}
  local arr_idx = 1
  local pos = 1

  while pos <= #s do
    -- parse size
    local size_str = s:match('^(%d+)', pos)
    if not size_str then
      break
    end
    local size = tonumber(size_str)
    pos = pos + #size_str

    -- parse size
    local chunk = s:sub(pos, pos + size - 1)
    pos = pos + size

    local key, vtype, vstr
    local at_pos = chunk:find('@', 1, true)

    if at_pos then
      -- is kv
      key = chunk:sub(1, at_pos - 1)
      local rest = chunk:sub(at_pos + 1)
      vtype = rest:sub(1, 1)
      vstr = rest:sub(3)
    else
      -- is array item
      vtype = chunk:sub(1, 1)
      vstr = chunk:sub(3)
    end

    local val
    if vtype == 's' then
      val = unmangle_str(vstr)
    elseif vtype == 'n' then
      val = tonumber(vstr)
    elseif vtype == 'b' then
      val = vstr == '1'
    else
      error('Unknown vtype: ' .. vtype)
    end

    if key then
      tbl[unmangle_str(key)] = val
    else
      tbl[arr_idx] = val
      arr_idx = arr_idx + 1
    end
  end

  return tbl
end

function M.unit_test()
  local test_cases = {
    {
      name = 'original 1',
      input = { 1, 2, 3, foo = 'bar', xxx = 114514, yyy = true },
    },
    {
      name = 'original 2',
      input = {
        '/home/aurora/Workspace/nvim-config/dev/session',
        name = 'xxxyyy',
        date = '2026-7-20',
        mail = 'foobar@xxxyyy',
      },
    },

    { name = 'empty table', input = {} },

    { name = 'array only', input = { 10, 20, 30 } },
    {
      name = 'array with mixed types',
      input = { 'hello', 42, false, true, 'world' },
    },

    { name = 'hash only', input = { a = 1, b = '2', c = true, d = false } },

    { name = 'number edge cases', input = { 0, -1, 3.14, 1e10, -0.001 } },

    { name = 'boolean values', input = { true, false, ok = true, no = false } },

    {
      name = 'special chars in keys and values',
      input = {
        ['weird@key'] = 'val:with:colon',
        ['percent%key'] = '100%',
        ['a=b'] = 'c&d',
        ['spaces and 中文'] = 'emoji🎉',
        [''] = 'empty key',
      },
    },

    { name = 'empty string value', input = { '' } },
    { name = 'empty key', input = { [''] = 'empty' } },

    {
      name = 'string with delimiters',
      input = { 'foo@bar', 'key:val', 'percent%here' },
    },

    { name = 'value zero', input = { zero = 0, nzero = -0 } },

    {
      name = 'mixed array and hash',
      input = { 1, 2, a = 3, b = 4, 5 },
    },
  }

  local function deep_equal(a, b)
    if vim and vim.deep_equal then
      return vim.deep_equal(a, b)
    end
    if type(a) ~= type(b) then
      return false
    end
    if type(a) ~= 'table' then
      return a == b
    end
    for k, v in pairs(a) do
      if not deep_equal(v, b[k]) then
        return false
      end
    end
    for k, _ in pairs(b) do
      if a[k] == nil then
        return false
      end
    end
    return true
  end

  local passed, failed = 0, 0
  for _, tc in ipairs(test_cases) do
    local ok, err = pcall(function()
      local encoded = M.encode(tc.input)
      local encoded2 = M.encode(tc.input)
      assert(encoded == encoded2)
      local decoded = M.decode(encoded)
      assert(
        deep_equal(decoded, tc.input),
        'roundtrip failed for '
          .. tc.name
          .. '\n'
          .. '  input:    '
          .. vim.inspect(tc.input)
          .. '\n'
          .. '  decoded:  '
          .. vim.inspect(decoded)
          .. '\n'
          .. '  encoded:  '
          .. encoded
      )
    end)
    if ok then
      passed = passed + 1
      print('✓ ' .. tc.name)
    else
      failed = failed + 1
      print('✗ ' .. tc.name .. ' : ' .. tostring(err))
    end
  end

  print(string.format('\n%d passed, %d failed', passed, failed))
end

return M

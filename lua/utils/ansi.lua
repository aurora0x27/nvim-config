--------------------------------------------------------------------------------
-- Ansi -- ANSI text to NvimMsgTuple conversion
--
-- Terminal output carries SGR escape sequences that describe colors and text
-- attributes. Neovim's message protocol instead represents styled text as
-- `{ attr_id, text, hl_id }` chunks, where `hl_id` refers to a highlight group.
--
-- This module parses ordinary ANSI text and materializes each distinct SGR
-- state as a cached highlight group, producing chunks that can be passed
-- directly to `utils.render.calculate_layout`.
--
-- ANSI palette slots 0-15 honor `vim.g.terminal_color_0` through
-- `vim.g.terminal_color_15`, so colorschemes can restyle base colors. Unset or
-- invalid slots fall back to the built-in xterm palette.
--
-- Neovim's `msg_show` text uses caret notation for ESC ("^["), while process
-- output collected through `vim.system` keeps the raw byte. Call `normalize`
-- on the former before feeding either representation to `to_tuples`.
--------------------------------------------------------------------------------
local M = {}

local ESC = '\27'
local BEL = '\7'

-- Xterm colors 0-15. Higher indexed colors are generated from the xterm cube.
---@type [integer, integer, integer][]
local BASE_COLORS = {
  { 0x00, 0x00, 0x00 },
  { 0x80, 0x00, 0x00 },
  { 0x00, 0x80, 0x00 },
  { 0x80, 0x80, 0x00 },
  { 0x00, 0x00, 0x80 },
  { 0x80, 0x00, 0x80 },
  { 0x00, 0x80, 0x80 },
  { 0xc0, 0xc0, 0xc0 },
  { 0x80, 0x80, 0x80 },
  { 0xff, 0x00, 0x00 },
  { 0x00, 0xff, 0x00 },
  { 0xff, 0xff, 0x00 },
  { 0x00, 0x00, 0xff },
  { 0xff, 0x00, 0xff },
  { 0x00, 0xff, 0xff },
  { 0xff, 0xff, 0xff },
}

---@class AnsiSgrState
---@field fg? string
---@field bg? string
---@field ctermfg? integer
---@field ctermbg? integer
---@field bold? boolean
---@field dim? boolean
---@field italic? boolean
---@field underline? boolean
---@field underdouble? boolean
---@field reverse? boolean
---@field strikethrough? boolean

---@return AnsiSgrState
local function new_state()
  return {}
end

---@param state AnsiSgrState
local function reset_state(state)
  state.fg = nil
  state.bg = nil
  state.ctermfg = nil
  state.ctermbg = nil
  state.bold = nil
  state.dim = nil
  state.italic = nil
  state.underline = nil
  state.underdouble = nil
  state.reverse = nil
  state.strikethrough = nil
end

---@param s string
---@param sep string
---@return string[]
local function split(s, sep)
  local parts = {}
  local start = 1
  while true do
    local pos = s:find(sep, start, true)
    if not pos then
      parts[#parts + 1] = s:sub(start)
      break
    end
    parts[#parts + 1] = s:sub(start, pos - 1)
    start = pos + 1
  end
  return parts
end

---@param n integer
---@return integer, integer, integer
local function xterm_rgb(n)
  if n < 16 then
    -- ANSI 0-15 are terminal palette slots. Honor Neovim's terminal palette so
    -- colorschemes (for example catppuccin with term_colors enabled) can
    -- restyle them; fall back to the built-in xterm values when unset.
    local value = vim.g['terminal_color_' .. n]
    if type(value) == 'string' then
      local color = vim.api.nvim_get_color_by_name(value)
      if color >= 0 then
        local r = math.floor(color / 65536) % 256
        local g = math.floor(color / 256) % 256
        local b = color % 256
        return r, g, b
      end
    end

    local c = BASE_COLORS[n + 1]
    return c[1], c[2], c[3]
  end
  if n < 232 then
    local level = { 0, 95, 135, 175, 215, 255 }
    local offset = n - 16
    local r = math.floor(offset / 36)
    local g = math.floor(offset / 6) % 6
    local b = offset % 6
    return level[r + 1], level[g + 1], level[b + 1]
  end
  local v = 8 + (n - 232) * 10
  return v, v, v
end

---@param r integer
---@param g integer
---@param b integer
---@return string
local function rgb_hex(r, g, b)
  return string.format('#%02x%02x%02x', r, g, b)
end

---@param n integer
---@return boolean
local function valid_color(n)
  return n >= 0 and n <= 255 and n % 1 == 0
end

---@param state AnsiSgrState
---@param is_fg boolean
---@param n integer
local function set_indexed(state, is_fg, n)
  if not valid_color(n) then
    return
  end
  local r, g, b = xterm_rgb(n)
  if is_fg then
    state.fg = rgb_hex(r, g, b)
    state.ctermfg = n
  else
    state.bg = rgb_hex(r, g, b)
    state.ctermbg = n
  end
end

---@param state AnsiSgrState
---@param is_fg boolean
---@param r integer
---@param g integer
---@param b integer
local function set_rgb(state, is_fg, r, g, b)
  if not (valid_color(r) and valid_color(g) and valid_color(b)) then
    return
  end
  if is_fg then
    state.fg = rgb_hex(r, g, b)
    state.ctermfg = nil
  else
    state.bg = rgb_hex(r, g, b)
    state.ctermbg = nil
  end
end

---@param params string
---@param state AnsiSgrState
local function parse_sgr(params, state)
  if params == '' then
    reset_state(state)
    return
  end

  local groups = split(params, ';')
  local i = 1
  while i <= #groups do
    local group = groups[i]

    if group == '' then
      -- An empty parameter is treated as SGR 0.
      reset_state(state)
      i = i + 1
    else
      local parts = split(group, ':')
      local code = tonumber(parts[1])

      if not code then
        i = i + 1
      elseif code == 38 or code == 48 then
        local is_fg = code == 38

        if #parts > 1 then
          -- Colon form: 38:5:n or 38:2:[colorspace]:r:g:b.
          local mode = tonumber(parts[2])
          if mode == 5 then
            local n = tonumber(parts[3])
            if n then
              set_indexed(state, is_fg, n)
            end
          elseif mode == 2 then
            local nums = {}
            for j = 3, #parts do
              local n = tonumber(parts[j])
              if n then
                nums[#nums + 1] = n
              end
            end
            if #nums >= 3 then
              set_rgb(
                state,
                is_fg,
                nums[#nums - 2],
                nums[#nums - 1],
                nums[#nums]
              )
            end
          end
          i = i + 1
        else
          -- Semicolon form: 38;5;n or 38;2;r;g;b.
          local mode = tonumber(groups[i + 1])
          if mode == 5 then
            local n = tonumber(groups[i + 2])
            if n then
              set_indexed(state, is_fg, n)
            end
            i = i + 3
          elseif mode == 2 then
            local r = tonumber(groups[i + 2])
            local g = tonumber(groups[i + 3])
            local b = tonumber(groups[i + 4])
            if r and g and b then
              set_rgb(state, is_fg, r, g, b)
            end
            i = i + 5
          else
            i = i + 2
          end
        end
      else
        local fg = code >= 30 and code <= 37
        local bg = code >= 40 and code <= 47
        local bright_fg = code >= 90 and code <= 97
        local bright_bg = code >= 100 and code <= 107

        if fg then
          set_indexed(state, true, code - 30)
        elseif bg then
          set_indexed(state, false, code - 40)
        elseif bright_fg then
          set_indexed(state, true, code - 90 + 8)
        elseif bright_bg then
          set_indexed(state, false, code - 100 + 8)
        elseif code == 0 then
          reset_state(state)
        elseif code == 1 then
          state.bold = true
        elseif code == 2 then
          state.dim = true
        elseif code == 3 then
          state.italic = true
        elseif code == 4 then
          state.underline = true
          state.underdouble = nil
        elseif code == 7 then
          state.reverse = true
        elseif code == 9 then
          state.strikethrough = true
        elseif code == 21 then
          state.underdouble = true
          state.underline = nil
        elseif code == 22 then
          state.bold = nil
          state.dim = nil
        elseif code == 23 then
          state.italic = nil
        elseif code == 24 then
          state.underline = nil
          state.underdouble = nil
        elseif code == 27 then
          state.reverse = nil
        elseif code == 29 then
          state.strikethrough = nil
        elseif code == 39 then
          state.fg = nil
          state.ctermfg = nil
        elseif code == 49 then
          state.bg = nil
          state.ctermbg = nil
        end

        i = i + 1
      end
    end
  end
end

---@type table<string, integer>
local hl_cache = {}

local hl_seq = 0

---@param state AnsiSgrState
---@return string
local function state_key(state)
  return table.concat({
    state.fg or '',
    state.bg or '',
    state.ctermfg or '',
    state.ctermbg or '',
    state.bold and 'b' or '',
    state.dim and 'd' or '',
    state.italic and 'i' or '',
    state.underline and 'u' or '',
    state.underdouble and 'U' or '',
    state.reverse and 'r' or '',
    state.strikethrough and 's' or '',
  }, '|')
end

---@param state AnsiSgrState
---@return boolean
local function has_style(state)
  return state.fg ~= nil
    or state.bg ~= nil
    or state.bold ~= nil
    or state.dim ~= nil
    or state.italic ~= nil
    or state.underline ~= nil
    or state.underdouble ~= nil
    or state.reverse ~= nil
    or state.strikethrough ~= nil
end

---@param state AnsiSgrState
---@return integer
local function state_hl(state)
  if not has_style(state) then
    return 0
  end

  local key = state_key(state)
  local cached = hl_cache[key]
  if cached then
    return cached
  end

  hl_seq = hl_seq + 1
  local name = 'AnsiTxt_' .. hl_seq

  ---@type vim.api.keyset.highlight
  local spec = {}
  if state.fg then
    spec.fg = state.fg
  end
  if state.bg then
    spec.bg = state.bg
  end
  if state.ctermfg then
    spec.ctermfg = state.ctermfg
  end
  if state.ctermbg then
    spec.ctermbg = state.ctermbg
  end
  if state.bold then
    spec.bold = true
  end
  if state.dim then
    spec.dim = true
  end
  if state.italic then
    spec.italic = true
  end
  if state.underline then
    spec.underline = true
  end
  if state.underdouble then
    spec.underdouble = true
  end
  if state.reverse then
    spec.reverse = true
  end
  if state.strikethrough then
    spec.strikethrough = true
  end

  vim.api.nvim_set_hl(0, name, spec)

  local id = vim.api.nvim_get_hl_id_by_name(name)
  hl_cache[key] = id
  return id
end

--- Normalize Neovim's caret-escaped text to ordinary ANSI.
---
--- Neovim represents ESC (0x1b) as the two-byte sequence "^[" in `msg_show`
--- content. Raw ANSI already has ESC and is returned unchanged.
---@param s string
---@return string
function M.normalize(s)
  assert(type(s) == 'string', 'ansi.normalize: expected string')
  return (s:gsub('%^%[', function()
    return ESC
  end))
end

---@param s string|string[]
---@return NvimMsgTuple[]
local function to_tuples_impl(s)
  local text
  if type(s) == 'string' then
    text = s
  elseif type(s) == 'table' then
    local parts = {}
    for i = 1, #s do
      local line = s[i]
      if type(line) ~= 'string' then
        error('ansi.to_tuples: expected string or string[]', 2)
      end
      parts[i] = line
    end
    text = table.concat(parts, '\n')
  else
    error('ansi.to_tuples: expected string or string[]', 2)
  end

  local tuples = {}
  local line_tuples = {}
  local state = new_state()

  -- A carriage return without a newline moves the cursor back to column zero.
  -- The next visible character overwrites the current line. Keep the pending
  -- CR until that happens so a CR at the end of one chunk followed by a
  -- newline in the next chunk does not create an extra blank line.
  local pending_cr = false

  ---@param str string
  ---@param hl_id integer
  local function append_line(str, hl_id)
    if str == '' then
      return
    end
    local last = line_tuples[#line_tuples]
    if last and last[3] == hl_id then
      last[2] = last[2] .. str
    else
      line_tuples[#line_tuples + 1] = { 0, str, hl_id }
    end
  end

  local function flush_line()
    for _, tuple in ipairs(line_tuples) do
      tuples[#tuples + 1] = tuple
    end
    tuples[#tuples + 1] = { 0, '\n', 0 }
    line_tuples = {}
  end

  ---@param str string
  ---@param hl_id integer
  local function append_visible(str, hl_id)
    if str == '' then
      return
    end
    if pending_cr then
      line_tuples = {}
      pending_cr = false
    end
    append_line(str, hl_id)
  end

  ---@param chunk string
  local function emit(chunk)
    if chunk == '' then
      return
    end
    local hl_id = state_hl(state)
    local start = 1
    while start <= #chunk do
      local cr = chunk:find('\r', start, true)
      local nl = chunk:find('\n', start, true)
      local stop = cr and nl and math.min(cr, nl) or cr or nl
      if not stop then
        append_visible(chunk:sub(start), hl_id)
        break
      end
      if stop > start then
        append_visible(chunk:sub(start, stop - 1), hl_id)
      end
      if stop == cr then
        pending_cr = true
      else
        pending_cr = false
        flush_line()
      end
      start = stop + 1
    end
  end

  local pos = 1
  while true do
    local esc = text:find(ESC, pos, true)
    if not esc then
      emit(text:sub(pos))
      break
    end

    emit(text:sub(pos, esc - 1))

    local kind = text:sub(esc + 1, esc + 1)
    local next_pos

    if kind == '[' then
      -- CSI: parameters followed by a final byte in the range 0x40-0x7e.
      local final = esc + 2
      while final <= #text do
        local byte = text:byte(final)
        if byte and byte >= 0x40 and byte <= 0x7e then
          break
        end
        final = final + 1
      end

      if final > #text then
        next_pos = #text + 1
      else
        if text:sub(final, final) == 'm' then
          parse_sgr(text:sub(esc + 2, final - 1), state)
        end
        next_pos = final + 1
      end
    elseif kind == ']' then
      -- OSC: terminated by BEL or ST. Neovim may strip BEL, so fall back to
      -- consuming the rest of the line when no terminator is present.
      local bel = text:find(BEL, esc + 2, true)
      local st = text:find(ESC .. '\\', esc + 2, true)
      if bel and (not st or bel < st) then
        next_pos = bel + 1
      elseif st then
        next_pos = st + 2
      else
        local nl = text:find('\n', esc + 2, true)
        next_pos = nl or (#text + 1)
      end
    elseif kind == 'P' or kind == 'X' or kind == '^' or kind == '_' then
      -- DCS, SOS, PM and APC: consume until ST.
      local st = text:find(ESC .. '\\', esc + 2, true)
      next_pos = st and (st + 2) or (#text + 1)
    elseif
      kind == '('
      or kind == ')'
      or kind == '*'
      or kind == '+'
      or kind == '-'
      or kind == '.'
      or kind == '/'
    then
      -- Charset selection: ESC, an intermediate byte, then the charset byte.
      next_pos = esc + 3
    elseif kind == '' then
      next_pos = #text + 1
    else
      -- Single-character escape.
      next_pos = esc + 2
    end

    if next_pos > #text then
      break
    end
    pos = next_pos
  end

  if #line_tuples > 0 then
    for _, tuple in ipairs(line_tuples) do
      tuples[#tuples + 1] = tuple
    end
  end

  return tuples
end

--- Convert ordinary ANSI text to NvimMsgTuple[].
---
--- `string[]` is treated as a list of lines and joined with newlines. The
--- returned chunks contain newlines as separate tuples; `utils.render`
--- `calculate_layout` splits or joins them into buffer lines. Adjacent chunks
--- with the same highlight within a line are merged. A carriage return without
--- a following newline overwrites the current line, matching terminal output.
---
--- This function never throws. On failure it returns `false` and an error
--- message; on success it returns `true` and the chunk list.
---@param s string|string[]
---@return boolean ok
---@return NvimMsgTuple[]|string
function M.to_tuples(s)
  local ok, ret = pcall(to_tuples_impl, s)
  if not ok then
    return false, tostring(ret)
  end
  return true, ret
end

return M

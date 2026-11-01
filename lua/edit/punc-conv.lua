--------------------------------------------------------------------------------
-- Punctuation converter
--
-- Normalize Chinese text: full-width punctuation to half-width, while keeping
-- visual width intact.
--
-- Motivation
--   Text copied from elsewhere is usually full-width punctuation; this lowers
--   it to half-width so it mixes cleanly with ASCII.
--
-- Width model
--   A CJK glyph is treated as exactly twice the width of an ASCII character.
--   Half-width spaces are the width-compensation unit:
--   - a lowered clause punctuation (，。、；：！？) is followed by exactly one
--     space, collapsing any existing run;
--   - a full-width space (U+3000) becomes two half-width spaces.
--
-- Corner brackets
--   《》 and 〈〉 are NOT lowered to ASCII quotes; they normalize to the corner
--   brackets 『』 and 「」. Only “” and ‘’ become " and '.
--
-- Note
--   The extra space after lowered punctuation is intentional even in pure
--   CJK text (width compensation), not a bug.
--------------------------------------------------------------------------------
local M = {}
local LOG_TITLE = 'PuncConv'
local log = require 'utils.logger'.new(LOG_TITLE)

local PuncMap = {
  ['，'] = ',',
  ['。'] = '.',
  ['、'] = ',',
  ['；'] = ';',
  ['：'] = ':',
  ['！'] = '!',
  ['？'] = '?',

  ['（'] = '(',
  ['）'] = ')',
  ['“'] = '"',
  ['”'] = '"',
  ['‘'] = "'",
  ['’'] = "'",
  ['【'] = '[',
  ['】'] = ']',
  ['《'] = '『',
  ['》'] = '』',
  ['〈'] = '「',
  ['〉'] = '」',
  ['　'] = '  ',
}

local Padding = {
  ['，'] = true,
  ['。'] = true,
  ['、'] = true,
  ['；'] = true,
  ['：'] = true,
  ['！'] = true,
  ['？'] = true,
}

local function utf8chars(s)
  local chars = {}
  local i, n = 1, #s
  while i <= n do
    local b = s:byte(i)
    local len = 1
    if b >= 0xF0 then
      len = 4
    elseif b >= 0xE0 then
      len = 3
    elseif b >= 0xC0 then
      len = 2
    end
    chars[#chars + 1] = s:sub(i, i + len - 1)
    i = i + len
  end
  return chars
end

local function convert_line(line)
  local chars = utf8chars(line)
  local out = {}
  local i = 1

  while i <= #chars do
    local c = chars[i]

    local repl = PuncMap[c]

    if repl then
      out[#out + 1] = repl
      i = i + 1
      if Padding[c] then
        while chars[i] == ' ' do
          i = i + 1
        end

        if i <= #chars then
          out[#out + 1] = ' '
        end
      end
    else
      out[#out + 1] = c
      i = i + 1
    end
  end

  return table.concat(out)
end

local _initialized = false

function M.setup()
  if _initialized then
    log.error 'Should not initialize module twice'
    return
  end
  vim.api.nvim_create_user_command('PuncConv', function(opts)
    local lines =
      vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
    local new = {}
    for i, line in ipairs(lines) do
      new[i] = convert_line(line)
    end
    vim.api.nvim_buf_set_lines(0, opts.line1 - 1, opts.line2, false, new)
  end, {
    range = '%',
    desc = 'Normalize full-width punctuation to half-width',
  })
  _initialized = true
end

return M

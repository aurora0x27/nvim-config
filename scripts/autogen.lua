#!/bin/env -S nvim --clean --headless -l
--------------------------------------------------------------------------------
-- This script automatically generate defaults and type hint of Profile options
--------------------------------------------------------------------------------
---@class ProfileManifestDecl
---@field type          string
---@field default       string|number|boolean
---@field desc          string
---@field category      string
---@field i18n          table<string, string>
---@field enum?         string[]

---@private
---@class AutogenTargets
---@field runtime     boolean
---@field readme        boolean
local AUTOGEN_TARGETS_DEFAULT = {
  runtime = true,
  readme = true,
}

---@private
---@class AutogenOpts
---@field manifest   string
---@field defaults   string
---@field types      string
---@field target     AutogenTargets
---@field lang       string[]
local AUTOGEN_OPTIONS_DEFAULT = {
  manifest = 'assets/manifest.lua',
  defaults = 'lua/core/profile/defaults.lua',
  types = 'lua/core/profile/types.lua',
  lang = { '_', 'zh_CN' },
  target = AUTOGEN_TARGETS_DEFAULT,
}

local USAGE_FMT = [[
Usage:
    %s [OPTIONS]

Generate runtime files and documentation from Profile metadata.

Options:
    --manifest FILE
        Profile manifest and metadata file.

    --defaults FILE
        Output path of generated defaults.lua.

    --types FILE
        Output path of generated types.lua.

    --target FEATSTR
        Generation targets.

        Targets:
            runtime
            readme

        Keywords:
            full
            none

        Examples:
            full
            runtime
            none,+runtime
            full,-readme

    --lang LIST
        Documentation languages.

        '_'      -> README.md
        'zh_CN'  -> doc/README.zh_CN.md

    -h, --help
        Show this help message.

    -v, --verbose
]]

--------------------------------------------------------------------------------
--- Globals
--------------------------------------------------------------------------------
---@type table<string, string[]>
local Aliases = {}

---@type table<string, any>
local Defaults = {}

---@type table<string, {type: string, desc: string[]}>
local TypeHintsWithDoc = {}

---@type table<string, table<string, boolean>>
local Groups = {}

---@type boolean
local Verbose = false
--------------------------------------------------------------------------------
--- Globals
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--- Utils
--------------------------------------------------------------------------------
local sprintf = string.format

local function printf(fmt, ...)
  print(sprintf(fmt, ...))
end

local function vlogf(fmt, ...)
  if Verbose then
    print('[AUTOGEN] ' .. sprintf(fmt, ...))
  end
end

local uv = vim.uv
local api = vim.api

local function quote(s)
  return "'"
    .. s:gsub([=[[\\'\a\b\f\n\r\t\v\0]]]=], function(c)
      return ({
        ['\\'] = '\\\\',
        ["'"] = "\\'",
        ['\a'] = '\\a',
        ['\b'] = '\\b',
        ['\f'] = '\\f',
        ['\n'] = '\\n',
        ['\r'] = '\\r',
        ['\t'] = '\\t',
        ['\v'] = '\\v',
        ['\0'] = '\\0',
      })[c]
    end)
    .. "'"
end

-- implements stable kv iterator
local function sorted_pairs(tbl)
  local keys = {}

  for k in pairs(tbl) do
    keys[#keys + 1] = k
  end

  table.sort(keys)

  local i = 0

  return function()
    i = i + 1
    local k = keys[i]

    if k then
      return k, tbl[k]
    end
  end
end

local function serialize_impl(v, lvl)
  local t = type(v)

  if t == 'nil' then
    return 'nil'
  elseif t == 'number' or t == 'boolean' then
    return tostring(v)
  elseif t == 'string' then
    return quote(v)
  elseif t == 'table' then
    local parts = {}

    for k, val in sorted_pairs(v) do
      local key

      if type(k) == 'string' and k:match('^[_%a][_%w]*$') then
        key = k
      else
        key = '[' .. serialize_impl(k, lvl + 1) .. ']'
      end

      parts[#parts + 1] = string.rep('  ', lvl + 1)
        .. key
        .. ' = '
        .. serialize_impl(val, lvl + 1)
    end

    return '{\n'
      .. table.concat(parts, ',\n')
      .. '\n'
      .. string.rep('  ', lvl)
      .. '}'
  else
    error('unsupported type: ' .. t)
  end
end

local function serialize(v)
  return serialize_impl(v, 0)
end

local function split_string(s)
  local lines = vim.split(s, '\n', { plain = true })

  for i, line in ipairs(lines) do
    lines[i] = vim.trim(line)
  end

  while lines[1] == '' do
    table.remove(lines, 1)
  end

  while lines[#lines] == '' do
    table.remove(lines)
  end

  return lines
end

--- Feat string parser
---
--- String: `+foo,-bar,baz` means enable foo,baz and disable bar
--- keyword `full` means use full default options, `none` means
--- use the *not* of default options.
---
---@param feat_s string feat string
---@param defaults table<string, boolean> schema table
---@param on_error? fun(msg: string)
---@return table masked result
local function parse_featstr(feat_s, defaults, on_error)
  local mask = {}
  on_error = on_error or function(_) end
  for feat_item in string.gmatch(feat_s, '([^,]+)') do
    feat_item = vim.trim(feat_item)
    local first_char = feat_item:sub(1, 1)
    if feat_item == 'full' then
      for k, v in pairs(defaults) do
        mask[k] = v
      end
    elseif feat_item == 'none' then
      for k, v in pairs(defaults) do
        mask[k] = not v
      end
    else
      local feat_name = (first_char == '+' or first_char == '-')
          and feat_item:sub(2)
        or feat_item
      if type(defaults[feat_name]) == 'nil' then
        on_error(string.format('Unknown feature: %s', feat_name))
      else
        if first_char == '+' then
          mask[feat_name] = true
        elseif first_char == '-' then
          mask[feat_name] = false
        else
          mask[feat_name] = true
        end
      end
    end
  end
  return mask
end

local function resolve_readme(lang)
  if lang == '_' then
    return 'README.md'
  end
  return 'doc/README.' .. lang .. '.md'
end

---@param manifest table<string, ProfileManifestDecl>
---@param name string
---@param lang string
---@return string|nil
local function gettext(manifest, name, lang)
  if lang == '_' then
    return manifest[name].desc
  end
  return manifest[name].i18n[lang]
end

---@param s string
---@return table<string, boolean>
local function parse_to_set(s)
  local res = {}
  if s == '' or s == nil then
    return res
  end
  for item in string.gmatch(s, '([^,]+)') do
    local name = vim.trim(item)
    res[name] = true
  end
  return res
end

local BUILTIN_TYPES = {
  boolean = true,
  string = true,
  number = true,
}

---@param ty string
---@return boolean
local function is_builtin(ty)
  return BUILTIN_TYPES[ty] or false
end

---@param lang string
---@return string
local function normalize_lang(lang)
  return lang == '_' and 'en' or lang
end
--------------------------------------------------------------------------------
--- Utils
--------------------------------------------------------------------------------

---@param manifest table<string, ProfileManifestDecl>
local function collect_data(manifest)
  for name, decl in pairs(manifest) do
    vlogf('GOT OPTION `%s`...', name)
    assert(
      type(decl.default) ~= 'nil',
      sprintf('%s.default should not be nil', name)
    )
    assert(
      type(decl.category) == 'string',
      sprintf('%s.string should not be string', name)
    )
    assert(
      type(decl.type) == 'string',
      sprintf('%s.type should be `string`', name)
    )
    assert(
      type(decl.desc) == 'string',
      sprintf('%s.desc should be `string`', name)
    )

    if decl.enum then
      assert(
        vim.tbl_contains(decl.enum, decl.default),
        sprintf('%s.default `%s` is not in enum', name, decl.default)
      )
    end

    Defaults[name] = decl.default
    if not Groups[decl.category] then
      Groups[decl.category] = {}
    end
    Groups[decl.category][name] = true
    TypeHintsWithDoc[name] =
      { type = decl.type, desc = split_string(decl.desc) }

    if not is_builtin(decl.type) then
      assert(not Aliases[decl.type], sprintf('Redefined type `%s`', decl.type))
      assert(vim.islist(decl.enum), sprintf('%s.enum should be a list', name))
      Aliases[decl.type] = vim.list_slice(decl.enum)
    end
  end
end

local BANNER = [[
--------------------------------------------------------------------------------
-- WARN: This file is generated by script, DO NOT EDIT!
--------------------------------------------------------------------------------
-- luacheck: ignore 631 -- max line length
]]

local function gen_defaults(ofile)
  vlogf('GENERATING ' .. ofile .. ' ...')
  local content = BANNER .. 'return ' .. serialize(Defaults) .. '\n'
  vlogf('DEFAULTS FILE:\n' .. content)
  local fd, err = uv.fs_open(ofile, 'w', tonumber('644', 8))
  assert(fd, 'Cannot open `' .. ofile .. (err and '` because ' .. err or ''))
  uv.fs_write(fd, content, 0)
  uv.fs_close(fd)
end

local function gen_types(ofile)
  vlogf('GENERATING ' .. ofile .. ' ...')
  local lines = {}
  local fd, err = uv.fs_open(ofile, 'w', tonumber('644', 8))
  ---@param s string
  local function append_line(s)
    table.insert(lines, s)
  end
  local function new_line()
    table.insert(lines, '')
  end
  ---@param s string
  local function append_comment(s)
    append_line('---' .. s)
  end
  assert(fd, 'Cannot open `' .. ofile .. (err and '` because ' .. err or ''))

  for name, list in sorted_pairs(Aliases) do
    append_comment('@alias ' .. name)
    for _, item in ipairs(list) do
      append_comment('|' .. quote(item))
    end
    new_line()
  end

  append_comment('@class Profile')
  for name, item in sorted_pairs(TypeHintsWithDoc) do
    local first_line = '@field ' .. name .. ' ' .. item.type
    if #item.desc > 0 then
      first_line = first_line .. ' ' .. item.desc[1]
    end
    append_comment(first_line)
    if #item.desc > 1 then
      for i = 2, #item.desc do
        append_comment(string.rep(' ', 7) .. item.desc[i])
      end
    end
  end

  local content = BANNER .. table.concat(lines, '\n')
  vlogf('TYPE FILE:\n' .. content .. '\n')
  uv.fs_write(fd, content, 0)
  uv.fs_close(fd)
end

local DOCGEN_HEAD_PATTERN = '^%s*<!%-%-%s*docgen@profile%s*%-%->%s*$'
local DOCGEN_END_PATTERN = '^%s*<!%-%-%s*enddoc@profile%s*%-%->%s*$'

---@param buf integer
---@return integer, integer 0-based begin and end line, -1 if not found
local function find_marks(buf)
  local head_line = -1
  local end_line = -1

  local lines = api.nvim_buf_get_lines(buf, 0, -1, false)

  for i, line in ipairs(lines) do
    if line:find(DOCGEN_HEAD_PATTERN, 1, false) then
      assert(head_line == -1, 'duplicate docgen begin marker')
      head_line = i - 1
    end

    if line:find(DOCGEN_END_PATTERN, 1, false) then
      assert(end_line == -1, 'duplicate docgen end marker')
      end_line = i - 1
    end
  end

  if head_line >= 0 and end_line >= 0 and head_line < end_line then
    return head_line, end_line
  end

  return -1, -1
end

---@param manifest table<string, ProfileManifestDecl>
---@param lang string
---@param categories table<string, table<string,string>>
local function patch_readme(manifest, lang, categories)
  vlogf('PATCH Will patch lang `%s`', lang)
  local readme = resolve_readme(lang)
  assert(
    vim.fn.filewritable(readme) == 1 and vim.fn.filereadable(readme) == 1,
    sprintf('`%s` is not readable and writable', readme)
  )
  vlogf('PATCH Find file to patch: `%s`', readme)
  local buf = vim.fn.bufadd(readme)
  vim.fn.bufload(buf)
  local b, e = find_marks(buf)
  if b < 0 or e < 0 then
    vlogf('PATCH Cannot find marks')
    return
  end
  vlogf('PATCH Find range line %d-%d', b, e)

  local replace_lines = {}

  ---@param s string
  local function append_line(s)
    table.insert(replace_lines, s)
  end
  local function empty_line()
    table.insert(replace_lines, '')
  end

  empty_line()
  for group, items in sorted_pairs(Groups) do
    local i18n = categories[group]
    if not i18n then
      printf('Cannot get i18n of category `' .. group .. '`')
      goto continue
    end
    local category_text = i18n[normalize_lang(lang)]
    if not category_text then
      printf(
        'Cannot get `'
          .. lang
          .. '` text of category `'
          .. group
          .. '`, fallback to `en`'
      )
      category_text = i18n['en']
      if not category_text then
        printf('`en` text of `' .. group .. '` not found')
        goto continue
      end
    end
    append_line('- ' .. category_text)
    for item, _ in sorted_pairs(items) do
      local doctext = gettext(manifest, item, lang)
      local decl = manifest[item]
      if not doctext then
        printf(
          'PATCH Cannot get doc of `' .. item .. '`, lang = `' .. lang .. '`'
        )
        goto continue1
      end
      local doc = split_string(doctext)
      local first_line = '  - _`' .. item .. '`_'
      if #doc > 0 then
        first_line = first_line .. ' — ' .. doc[1]
      end
      append_line(first_line)
      local padding = string.rep(' ', 4)
      if #doc > 1 then
        for i = 2, #doc do
          append_line(padding .. doc[i])
        end
      end
      append_line(padding .. '- **Type:** `' .. decl.type .. '`')
      append_line(padding .. '- **ENV:** `NVIM_' .. string.upper(item) .. '`')
      append_line(
        padding .. '- **Defaults:** `' .. serialize(decl.default) .. '`'
      )
      if decl.enum then
        local values_line = padding .. '- **Values:** '
        for i, val in ipairs(decl.enum) do
          values_line = values_line .. padding .. '`' .. val
          if i == #decl.enum then
            values_line = values_line .. '`'
          else
            values_line = values_line .. '`,'
          end
        end
      end
      empty_line()
      ::continue1::
    end
    ::continue::
  end

  api.nvim_buf_set_lines(buf, b + 1, e, true, replace_lines)
  if not api.nvim_get_option_value('modified', { buf = buf }) then
    return
  end
  api.nvim_buf_call(buf, vim.cmd.write)
end

---@return AutogenOpts
local function parse_args()
  local opts = vim.deepcopy(AUTOGEN_OPTIONS_DEFAULT)
  local i = 1
  while i <= #_G.arg do
    local cur_arg = _G.arg[i]
    if cur_arg == '--manifest' then
      opts.manifest = assert(_G.arg[i + 1], '--manifest FILE needed')
      i = i + 1
    elseif cur_arg == '--defaults' then
      opts.defaults = assert(_G.arg[i + 1], '--defaults FILE needed')
      i = i + 1
    elseif cur_arg == '--types' then
      opts.types = assert(_G.arg[i + 1], '--types FILE needed')
      i = i + 1
    elseif cur_arg == '--target' then
      local target_str = assert(_G.arg[i + 1], '--target <FEATSTR> needed')
      opts.target = parse_featstr(
        target_str,
        AUTOGEN_TARGETS_DEFAULT,
        function(msg)
          print('ERROR: featstr syntax err `' .. msg .. '`')
          os.exit(1)
        end
      )
      i = i + 1
    elseif cur_arg == '--lang' then
      local lang_str = assert(_G.arg[i + 1], '--lang LIST needed')
      local lang_set = parse_to_set(lang_str)
      local langs = {}
      for lang, _ in sorted_pairs(lang_set) do
        table.insert(langs, lang)
      end
      opts.lang = langs
      i = i + 1
    elseif cur_arg == '--verbose' or cur_arg == '-v' then
      Verbose = true
    elseif cur_arg == '--help' or cur_arg == '-h' then
      printf(USAGE_FMT, _G.arg[0])
      os.exit(0)
    elseif vim.startswith(cur_arg, '-') then
      print('Unrecognized option:', cur_arg, '\n')
      os.exit(1)
    end
    i = i + 1
  end
  return opts
end

local function main()
  local opts = parse_args()
  vlogf('ARGS: %s', vim.inspect(opts))
  local ok, ret0, ret1 = pcall(dofile, opts.manifest)
  if not ok then
    print('ERROR: Cannot load manifest because `' .. ret0 .. '`')
    os.exit(1)
  end
  local decls = ret0
  local categories = ret1
  assert(type(decls) == 'table', 'Decls should be table')
  assert(type(categories) == 'table', 'Category should be table')
  vlogf('READ MANIFEST ' .. opts.manifest)
  collect_data(decls)
  if opts.target.runtime then
    gen_defaults(opts.defaults)
    gen_types(opts.types)
  end
  if opts.target.readme then
    for _, lang in ipairs(opts.lang) do
      patch_readme(decls, lang, categories)
    end
  end
end

main()

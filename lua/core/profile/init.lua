--------------------------------------------------------------------------------
-- Profile Module
--
-- Provide runtime profile resolution for the editor environment.
--
-- Profile is the configuration input layer used during runtime construction.
-- It collects configuration values from multiple sources, validates them
-- against the default schema, resolves precedence, and exposes a readonly
-- runtime profile object.
--
-- Configuration sources:
--
--   1. Environment variables (`env`)
--      Highest priority. Intended for temporary overrides, debug sessions,
--      CI/testing environments, and externally managed deployment settings.
--      Read from `NVIM_<KEY>`.
--
--   2. Workspace-local configuration (`local`)
--      An optional file passed through `opts.local_nvimrc`, normally the
--      workspace patch's `nvimrc.json`. It overrides the global configuration
--      for the current workspace only.
--
--   3. Global user configuration (`global`)
--      Default location:
--
--          stdpath("config") .. "/nvimrc.json"
--
--      Overrides the schema defaults.
--
--   4. Default schema (`default`)
--      Built-in fallback values generated from:
--
--          core.profile.defaults
--
-- Priority:
--
--      env > local > global > default
--
-- Configuration values are resolved once during startup. After setup(), the
-- profile should be treated as immutable runtime metadata.
--
--
-- Configuration files
--
-- Profile accepts JSON objects whose keys must exist in the default schema.
-- Unknown keys are ignored with a warning. A type mismatch rejects the whole
-- configuration source, so the previous level stays in effect.
--
-- At most one workspace-local file is supported. It is merged after the global
-- user file and before environment variables.
--
-- Every key reports the level that last supplied it (`default`, `global`,
-- `local` or `env`); see `debug_info()`.
--
-- String values support placeholder expansion:
--
--      "$@"
--
-- represents the current resolved value. This makes list-like options (for
-- example `lang_levels` and `lang_blacklist`) inheritable between levels:
-- a workspace file can extend the global value instead of replacing it.
--
-- Example:
--
--      {
--          "cache_dir": "$@/extra"
--      }
--
--
-- Environment overrides
--
-- Every profile key can be overridden through:
--
--      NVIM_<KEY>
--
-- Environment values are converted according to the type defined by defaults:
--
--   boolean:
--       "1" or "true" => true
--
--   number:
--       parsed through tonumber()
--
--   string:
--       supports "$@" replacement
--
-- Environment variables are applied after all configuration files have been
-- merged.
--
--
-- Runtime interface
--
-- The module exposes a readonly global profile object:
--
--      _G.Profile
--
-- Example:
--
--      Profile.lang_levels
--      Profile.persist_local_mode
--
-- Direct mutation is rejected:
--
--      Profile.foo = value
--
-- Profiles are intended to describe the runtime construction parameters, not
-- act as mutable application state.
--
--
-- Generated metadata
--
-- Default values are loaded from:
--
--      core.profile.defaults
--
-- Manifest file: assets/manifest.lua
--
-- This file acts as the schema source for:
--
--   * option defaults
--   * type validation
--   * environment variable conversion
--   * generated documentation
--
-- Run `make autogen` to generate everything
--
--
-- Debugging
--
-- `debug_info()` provides:
--
--   * resolved configuration path (`path`)
--   * final resolved values (`values`)
--   * keys overridden by environment variables (`masks`)
--   * the level that last supplied each key (`rc_source`)
--
-- `rc_source[key]` is one of:
--
--   * `default` — built-in schema value
--   * `global`  — global user `nvimrc.json`
--   * `local`   — workspace-local `nvimrc.json`
--   * `env`     — `NVIM_<KEY>` environment variable
--
--
-- Design notes
--
-- Profile intentionally separates configuration resolution from runtime
-- initialization.
--
-- Other subsystems should consume resolved profile values instead of reading
-- environment variables or configuration files directly.
--
-- This keeps runtime construction deterministic and allows the same editor
-- configuration to be instantiated under different environments.
--------------------------------------------------------------------------------
local M = {}
local LOG_TITLE = 'Profile Module'
local log = require 'utils.logger'.new(LOG_TITLE)
local warn = log.warn
local err = log.error
local uv = vim.uv or vim.loop

--- Read json without expecption
---@param path string
---@return any content
local function read_json(path)
  local fd = uv.fs_open(path, 'r', 438)
  if not fd then
    return nil
  end

  local stat = uv.fs_fstat(fd)
  if not stat then
    err('Cannot stat file `%s`', path)
    uv.fs_close(fd)
    return nil
  end

  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)

  if not data or data == '' then
    return nil
  end

  local ok, result = pcall(vim.json.decode, data)
  if not ok then
    err(result)
    return nil
  end

  return result
end

--- write formatted json file
---@param path string
---@param data table
---@return boolean success
local function write_json(path, data)
  local ok, res = pcall(vim.json.encode, data, { indent = '  ' })
  if not ok then
    err(res)
    return false
  end

  local fd = uv.fs_open(path, 'w', 438)
  if not fd then
    err('Cannot write file `%s`', path)
    return false
  end

  local bytes, write_err = uv.fs_write(fd, res, 0)
  uv.fs_close(fd)

  if not bytes then
    ---@diagnostic disable:param-type-mismatch
    err(write_err)
    return false
  end

  if bytes ~= #res then
    err('Partial write: %d/%d bytes written to `%s`', bytes, #res, path)
    return false
  end

  return true
end

local DEFAULTS = require 'core.profile.defaults'
local DEFAULT_KEYS = vim.tbl_keys(DEFAULTS)
local RAW_LAZY_SPECS = require 'utils.datadir'.load_set(
  'plugins.opt',
  err,
  function(set, k, v)
    v.enabled = false
    set[table.concat(k, '.')] = v
  end
)

---@alias NvimrcSourceTy
---| 'default'
---| 'global'
---| 'local'
---| 'env'

---@param src NvimrcSourceTy
---@return table<string, NvimrcSourceTy>
local function init_source(src)
  local ret = {}
  for _, k in ipairs(DEFAULT_KEYS) do
    ret[k] = src
  end
  return ret
end

---@type table<string, NvimrcSourceTy>?
local NvimrcSource

function M.get_filtered_opt_specs(filters)
  local result = {}
  local specs = vim.deepcopy(RAW_LAZY_SPECS or {})
  for name, spec in pairs(specs) do
    for _, filter in ipairs(filters) do
      filter(name, spec)
    end
    table.insert(result, spec)
  end
  return result
end

---@return table?
local function try_load_nvimrc(config_path)
  if not uv.fs_stat(config_path) then
    warn 'Cannot stat nvimrc.json, write in default config...'
    write_json(config_path, DEFAULTS)
    return nil
  end

  local res = read_json(config_path)
  if not res then
    err 'Fail to read nvimrc.json, fall back to default'
    return nil
  end

  return res
end

local Nvimrc
local NvimrcPath

---@class ProfileOpt
---@field config_path? string path to the global `nvimrc.json`; defaults to `stdpath('config') .. '/nvimrc.json'`
---@field local_nvimrc? string path to the workspace-local `nvimrc.json`, merged after the global file

---@param str string
---@param pat string
---@param repl string
---@param pos integer
---@return string, boolean, integer
local function safe_replace(str, pat, repl, pos)
  local s, e = string.find(str, pat, pos, true)
  if not s then
    return str, false, pos
  end
  return str:sub(1, s - 1) .. repl .. str:sub(e + 1), true, s + #repl
end

---@param str string
---@param pat string
---@param repl string
---@return string
local function safe_replace_all(str, pat, repl)
  local ret, loop, pos = str, true, 1
  while loop do
    ret, loop, pos = safe_replace(ret, pat, repl, pos)
  end
  return ret
end

---@param tbl table
---@return boolean ok, string err
local function schema_check(tbl)
  local ok = true
  local errmsg = {}
  for k, v in pairs(tbl) do
    local ty_s = type(DEFAULTS[k])
    local ty_v = type(v)
    if ty_s == 'nil' then
      warn('`%s` is not expected to appear in config', k)
    elseif ty_s ~= ty_v then
      ok = false
      table.insert(
        errmsg,
        string.format(
          '`%s` is expected as `%s`, but has type `%s`\n',
          k,
          ty_s,
          ty_v
        )
      )
    end
  end
  return ok, table.concat(errmsg, '\n')
end

---@param base table
---@param tbl table
---@param src NvimrcSourceTy
local function merge_cfg(base, tbl, src)
  for _, k in ipairs(DEFAULT_KEYS) do
    local new_val = tbl[k]
    if new_val ~= nil then
      if type(new_val) == 'string' then
        base[k] = safe_replace_all(new_val, '$@', base[k])
      else
        base[k] = new_val
      end
      NvimrcSource[k] = src
    end
  end
end

---@param tbl table?
---@param ty NvimrcSourceTy
local function check_and_merge(tbl, ty)
  if tbl and tbl ~= vim.NIL and type(tbl) == 'table' then
    local loaded_safe, err_msg = schema_check(tbl)
    if loaded_safe then
      merge_cfg(Nvimrc, tbl, ty)
    else
      err('%s config is ill formed: %s', ty, err_msg)
    end
  else
    err('%s config is not a JSON table', ty)
  end
end

---@param opts? ProfileOpt
function M.setup(opts)
  opts = opts or {}
  NvimrcPath = opts.config_path or vim.fn.stdpath('config') .. '/nvimrc.json'
  Nvimrc = vim.deepcopy(DEFAULTS)
  NvimrcSource = init_source 'default'

  local global_nvimrc = try_load_nvimrc(NvimrcPath)
  if global_nvimrc then
    check_and_merge(global_nvimrc, 'global')
  end

  if opts.local_nvimrc then
    if type(opts.local_nvimrc) == 'string' then
      local local_nvimrc = read_json(opts.local_nvimrc)
      if local_nvimrc then
        check_and_merge(local_nvimrc, 'local')
      end
    else
      warn(
        '`opts.local_nvimrc` is provided but not a string: `%s`',
        vim.inspect(opts.local_nvimrc)
      )
    end
  end

  -- environment mask
  for _, k in ipairs(DEFAULT_KEYS) do
    local v = Nvimrc[k]
    local env_name = 'NVIM_' .. k:upper()
    ---@type string|nil
    local env_val = vim.env[env_name]
    if env_val then
      local ty = type(v)
      if ty == 'boolean' then
        Nvimrc[k] = (env_val == '1' or env_val == 'true')
        NvimrcSource[k] = 'env'
      elseif ty == 'number' then
        local num = tonumber(env_val)
        if num then
          ---@type number
          Nvimrc[k] = num
          NvimrcSource[k] = 'env'
        else
          warn('Env %s is not a valid number', env_name)
        end
      elseif ty == 'string' then
        -- `$@` is replaced with current value of the option
        local val = safe_replace_all(env_val, '$@', Nvimrc[k])
        Nvimrc[k] = val
        NvimrcSource[k] = 'env'
      end
    end
  end
end

function M.get_raw_tbl()
  return Nvimrc
end

function M.get_defaults()
  return DEFAULTS
end

function M.debug_info()
  local rc_source = NvimrcSource and vim.deepcopy(NvimrcSource) or {}
  local info = {
    path = NvimrcPath,
    values = vim.deepcopy(Nvimrc),
    masks = {},
    rc_source = rc_source,
  }
  for k, v in require 'utils.tblx'.sorted_pairs(rc_source) do
    if v == 'env' then
      table.insert(info.masks, k)
    end
  end
  return info
end

local Profile = setmetatable(M, {
  __index = function(_, key)
    local ret = Nvimrc[key]
    if ret == nil then
      log.error('unknown key `%s`', key)
    end
    return ret
  end,
  __newindex = function(_, key)
    log.error('attempt to modify key `%s`', key)
  end,
})

---@type Profile
_G.Profile = Profile

return M

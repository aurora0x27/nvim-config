--------------------------------------------------------------------------------
-- Profile Module
--
-- Parse `nvimrc.json` and mask the values with environment variables.
-- Priority:
-- env > nvimrc.json > default(schema)
--------------------------------------------------------------------------------
local M = {}

local uv = vim.uv or vim.loop

---@param msg string
local function err(msg)
  vim.notify(msg, vim.log.levels.ERROR, { title = 'Profile Module' })
end

---@param msg string
local function warn(msg)
  vim.notify(msg, vim.log.levels.WARN, { title = 'Profile Module' })
end

--- Read json without expecption
---@param path string
---@return table|nil content
local function read_json(path)
  local fd = uv.fs_open(path, 'r', 438)
  if not fd then
    return nil
  end

  local stat = uv.fs_fstat(fd)
  if not stat then
    err(string.format('Cannot stat file `%s`', path))
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
  local ok, res = pcall(vim.json.encode, data)
  if not ok then
    err(res)
    return false
  end

  local fd = uv.fs_open(path, 'w', 438)
  if not fd then
    err(string.format('Cannot write file `%s`', path))
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
    err(
      string.format(
        'Partial write: %d/%d bytes written to `%s`',
        bytes,
        #res,
        path
      )
    )
    return false
  end

  return true
end

local SCHEMA = require 'core.profile.schema'
local RAW_LAZY_SPECS = require 'utils.loader'.load_data_dir_as_set(
  'plugins.opt',
  err,
  function(set, k, v)
    v.enabled = false
    set[table.concat(k, '.')] = v
  end
)

function M.create_lazy_spec_mask_builder()
  local current_set = vim.deepcopy(RAW_LAZY_SPECS or {})
  local builder = {}

  --- use callback to process each element
  ---@param cb fun(name: string, spec: table)
  function builder:pipe(cb)
    for name, spec in pairs(current_set) do
      cb(name, spec)
    end
    return self
  end

  -- Output flattened lazy spec table
  function builder.unpack()
    local result = {}
    for _, spec in pairs(current_set) do
      if spec then
        table.insert(result, spec)
      end
    end
    return result
  end

  return builder
end

---@return table
local function try_load_nvimrc(config_path)
  if not uv.fs_stat(config_path) then
    warn 'Cannot stat nvimrc.json, write in default config...'
    write_json(config_path, SCHEMA)
    return SCHEMA
  end

  local res = read_json(config_path)
  if not res then
    err 'Fail to read nvimrc.json, fall back to default'
    return SCHEMA
  end
  ---@type table
  return res
end

local nvimrc
local nvimrc_path

---@class ProfileOpt
---@field config_path? string
---@field files_to_merge? string[]

local function safe_replace(str, placeholder, repl)
  local s, e = str:find(placeholder, 1, true)
  if not s then
    return str
  end
  return str:sub(1, s - 1) .. repl .. str:sub(e + 1)
end

---@param tbl table
---@return boolean ok, string err
local function schema_check(tbl)
  local ok = true
  local errmsg = {}
  for k, v in pairs(tbl) do
    local ty_s = type(SCHEMA[k])
    local ty_v = type(v)
    if ty_s == 'nil' then
      warn(string.format('`%s` is not expected to appear in config', k))
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

---@param base table base table, mutable
---@param ... table[] tables to merge
local function merge_cfg(base, ...)
  local to_merge = { ... }
  if #to_merge == 0 then
    return
  end
  for _, tbl in ipairs(to_merge) do
    for k, new_val in pairs(tbl) do
      if type(new_val) == 'string' then
        base[k] = safe_replace(new_val, '$@', base[k])
      else
        base[k] = new_val
      end
    end
  end
end

---@param opts? ProfileOpt
function M.setup(opts)
  opts = opts or {}
  nvimrc_path = opts.config_path or vim.fn.stdpath 'config' .. '/nvimrc.json'
  nvimrc = vim.deepcopy(SCHEMA)

  local data_to_merge = {}

  local loaded_data = try_load_nvimrc(nvimrc_path)
  local loaded_safe, err_msg = schema_check(loaded_data)

  if loaded_safe then
    table.insert(data_to_merge, loaded_data)
  else
    err('User config is ill formed: ' .. err_msg)
  end

  if opts.files_to_merge then
    if vim.islist(opts.files_to_merge) then
      for _, file in ipairs(opts.files_to_merge) do
        local data = read_json(file)
        if data and data ~= vim.NIL and type(data) == 'table' then
          local ok, emsg = schema_check(data)
          if ok then
            table.insert(data_to_merge, data)
          else
            err('config from file `' .. file .. '` is ill formed: ' .. emsg)
          end
        else
          err('Cannot read json from `' .. file .. '`')
        end
      end
    else
      warn(
        'Opts.files_to_merge is provided but is not a string[], detail:\n'
          .. vim.inspect(opts.files_to_merge)
      )
    end
  end

  -- resolve nvimrc
  merge_cfg(nvimrc, unpack(data_to_merge))

  -- environment mask
  for k, v in pairs(nvimrc) do
    local env_name = 'NVIM_' .. k:upper()
    ---@type string|nil
    local env_val = vim.env[env_name]
    if env_val then
      local ty = type(v)
      if ty == 'boolean' then
        nvimrc[k] = (env_val == '1' or env_val == 'true')
      elseif ty == 'number' then
        local num = tonumber(env_val)
        if num then
          ---@type number
          nvimrc[k] = num
        else
          warn(string.format('Env %s is not a valid number', env_name))
        end
      elseif ty == 'string' then
        -- `$@` is replaced with current value of the option
        local val = safe_replace(env_val, '$@', nvimrc[k])
        nvimrc[k] = val
      end
    end
  end
end

function M.get_raw_tbl()
  return nvimrc
end

function M.get_defaults()
  return SCHEMA
end

function M.debug_info()
  local info = {
    path = nvimrc_path,
    values = nvimrc,
    masks = {},
  }
  for k, _ in pairs(SCHEMA) do
    if vim.env['NVIM_' .. k:upper()] then
      table.insert(info.masks, k)
    end
  end
  return info
end

local Profile = setmetatable(M, {
  __index = function(_, key)
    return rawget(M, key) or (nvimrc and nvimrc[key])
  end,
})

_G.Profile = Profile

return Profile

--------------------------------------------------------------------------------
-- Datadir -- data dir loader utils
--------------------------------------------------------------------------------
local M = {}

local LOG_TITLE = 'Data Dir Utils'
local log = require 'utils.logger'.new(LOG_TITLE)

local uv = vim.uv or vim.loop

--Load all template files from the specified module path and concatenate them into a large table.
---@param module_root string prefix of module (such as 'user.templates')
---@param cb? fun(tbl: table):table|nil
---@param on_error? fun(msg: string)
---@return table concat_table Concatenate arrays of all template tables
function M.load_list(module_root, cb, on_error)
  local concat_table = {}
  local lua_root = vim.fn.stdpath 'config' .. '/lua/'
  local base_dir = lua_root .. module_root:gsub('%.', '/')
  cb = cb or function(tbl)
    return tbl
  end
  on_error = on_error or log.error

  ---@param dir string
  local function scan_dir(dir)
    local handle = uv.fs_scandir(dir)
    if not handle then
      return
    end
    while true do
      local name, ty = uv.fs_scandir_next(handle)
      if not name then
        break
      end
      local fullpath = dir .. '/' .. name
      if ty == 'directory' then
        scan_dir(fullpath)
      elseif ty == 'file' and name:sub(-4) == '.lua' then
        local rel_path =
          fullpath:sub(#lua_root + 1):gsub('%.lua$', ''):gsub('[/\\]', '.')
        local ok, mod = pcall(require, rel_path)
        if ok and type(mod) == 'table' then
          local allTable = true
          for _, entry in pairs(mod) do
            if type(entry) ~= 'table' then
              allTable = false
              break
            end
          end
          if allTable then
            for _, entry in pairs(mod) do
              local res = cb(entry)
              if res ~= nil then
                table.insert(concat_table, res)
              end
            end
          else
            local res = cb(mod)
            if res ~= nil then
              table.insert(concat_table, res)
            end
          end
        else
          on_error('Load Failed: ' .. rel_path)
        end
      end
    end
  end

  scan_dir(base_dir)

  return concat_table
end

---@param module_root string
---@param on_error? fun(msg: string)
---@param cb? fun(set: table<string,table>, k: string[], v: table)
---@return table<string, table>
function M.load_set(module_root, on_error, cb)
  local set = {}
  cb = cb or function(s, k, v)
    s[table.concat(k, '.')] = v
  end
  on_error = on_error or log.error

  local lua_root = vim.fn.stdpath 'config' .. '/lua/'
  local base_dir = lua_root .. module_root:gsub('%.', '/')
  local path_stack = {}

  ---@param dir string
  ---@param relative string
  local function scan_dir(dir, relative)
    local fd = uv.fs_scandir(dir)
    if not fd then
      return
    end

    while true do
      local name, ty = uv.fs_scandir_next(fd)
      if not name then
        break
      end

      local fullpath = dir .. '/' .. name
      local rel_path = relative ~= '' and (relative .. '/' .. name) or name

      if ty == 'directory' then
        path_stack[#path_stack + 1] = name
        scan_dir(fullpath, rel_path)
        path_stack[#path_stack] = nil
      elseif ty == 'file' and name:sub(-4) == '.lua' then
        local key = rel_path:sub(1, -5):gsub('[/\\]', '.')
        path_stack[#path_stack + 1] = name:sub(1, -5)
        local mod_path = module_root .. '.' .. key
        local ok, mod = pcall(require, mod_path)
        if ok and type(mod) == 'table' then
          cb(set, path_stack, mod)
        else
          on_error('Load Failed: ' .. mod_path)
        end
        path_stack[#path_stack] = nil
      end
    end
  end

  scan_dir(base_dir, '')

  return set
end

return M

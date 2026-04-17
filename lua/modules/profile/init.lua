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

local SCHEMA = require('config.assets.misc').ProfileSchema
local RAW_LAZY_SPECS = require('utils.loader').load_data_dir_as_set(
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
---@field config_path string

local function safe_replace(str, placeholder, repl)
    local s, e = str:find(placeholder, 1, true)
    if not s then
        return str
    end
    return str:sub(1, s - 1) .. repl .. str:sub(e + 1)
end

---@param opts? ProfileOpt
function M.setup(opts)
    opts = opts or {}
    nvimrc_path = opts.config_path or vim.fn.stdpath 'config' .. '/nvimrc.json'
    local defaults = vim.deepcopy(SCHEMA)
    local loaded_data = try_load_nvimrc(nvimrc_path)
    -- resolve nvimrc
    nvimrc = vim.tbl_deep_extend('force', defaults, loaded_data)
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
                    warn(
                        string.format('Env %s is not a valid number', env_name)
                    )
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

return setmetatable(M, {
    __index = function(_, key)
        return rawget(M, key) or (nvimrc and nvimrc[key])
    end,
})

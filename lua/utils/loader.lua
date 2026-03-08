local M = {}

local misc = require 'utils.misc'

local uv = vim.uv or vim.loop

---Load all template files from the specified module path and concatenate them into a large table.
---@param module_root string prefix of module (such as 'user.templates')
---@param cb? fun(tbl: table):table|nil
---@param on_error? fun(msg: string)
---@return table concat_table Concatenate arrays of all template tables
function M.load_data_dir_as_list(module_root, cb, on_error)
    local concat_table = {}
    local lua_root = vim.fn.stdpath 'config' .. '/lua/'
    local base_dir = lua_root .. module_root:gsub('%.', '/')
    cb = cb or function(tbl)
        return tbl
    end
    on_error = on_error or misc.err

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
                local rel_path = fullpath
                    :sub(#lua_root + 1)
                    :gsub('%.lua$', '')
                    :gsub('[/\\]', '.')
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
                    on_error('[load_module] Load Failed: ' .. rel_path)
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
function M.load_data_dir_as_set(module_root, on_error, cb)
    local set = {}
    cb = cb or function(s, k, v)
        s[table.concat(k, '.')] = v
    end
    on_error = on_error or misc.err

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
            local rel_path = relative ~= '' and (relative .. '/' .. name)
                or name

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
                    on_error('[load_data_dir_as_set] Load Failed: ' .. mod_path)
                end
                path_stack[#path_stack] = nil
            end
        end
    end

    scan_dir(base_dir, '')

    return set
end

---@brief Select a function from a module with lazy loading
--- Creates a closure that lazily loads a module and accesses a nested function when called.
--- This is useful for deferring module loading until the function is actually needed.
---
---@param module string The module path to be passed to `require()`
---@param ... string Field names to traverse in the module. Last element must be a callable function.
---@return function A closure that, when called, will:
---   1. Load the module with `require(module)` (first call only)
---   2. Traverse the field chain (e.g., `t[field1][field2]...`)
---   3. Call the final function with provided arguments
---
---@usage
--- ```lua
--- -- Single field access
--- local lazy_notify = M.thunk("vim", "notify")
--- lazy_notify("Hello", vim.log.levels.INFO)
---
--- -- Nested field access
--- local lazy_map = M.thunk("nvim-treesitter.ts_utils", "map")
--- -- Equivalent to: require("nvim-treesitter.ts_utils").map(...)
---
--- -- Multi-level nesting
--- local lazy_action = M.thunk("telescope.actions", "state", "select_default")
--- -- Will call: require("telescope.actions").state.select_default(...)
--- ```
function M.thunk(module, ...)
    local fields = { ... }
    local n = #fields

    -- Early return when only one param is in the pack
    if n == 1 then
        local f = fields[1]
        return function(...)
            return require(module)[f](...)
        end
    end

    return function(...)
        local t = require(module)
        for i = 1, n - 1 do
            t = t[fields[i]]
        end
        return t[fields[n]](...)
    end
end

local unpack_impl = table.unpack or unpack

---@brief Bind arguments to a function (partial application)
--- Creates a new function with pre-bound arguments. Useful for creating callbacks
--- with fixed parameters or deferring execution.
---
---@param fn function The target function to bind arguments to
---@param ... any Arguments to bind to the function
---@return function A zero-argument closure that, when called, executes `fn` with
--- the bound arguments. Returns whatever `fn` returns.
---
---@usage
--- ```lua
--- -- Basic argument binding
--- local say_hello = M.bind(print, "Hello, World!")
--- say_hello()  -- prints: Hello, World!
---
--- -- Multiple arguments
--- local notify_info = M.bind(vim.notify, "Task completed", vim.log.levels.INFO)
--- notify_info()  -- shows info notification
---
--- -- Combining with M.select for lazy execution
--- local lazy_notify = M.select("vim", "notify")
--- lazy_notify = M.bind(lazy_notify, "Config loaded", vim.log.levels.INFO)
--- -- Later, possibly in an autocommand:
--- lazy_notify()  -- Shows "Config loaded" notification
--- ```
function M.bind(fn, ...)
    local args = { ... }
    local n = select('#', ...)

    return function()
        return fn(unpack_impl(args, 1, n))
    end
end

return M

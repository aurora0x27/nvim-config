local M = {}

local log = require 'utils.tools'

---Load all template files from the specified module path and concatenate them into a large table.
---@param module_root string prefix of module (such as 'user.templates')
---@return table concat_table Concatenate arrays of all template tables
function M.load_module(module_root)
    local scan = require 'plenary.scandir'
    local concat_table = {}

    local lua_root = vim.fn.stdpath 'config' .. '/lua/'
    local base_dir = lua_root .. module_root:gsub('%.', '/')

    local files = scan.scan_dir(base_dir, {
        depth = math.huge,
        add_dirs = false,
        search_pattern = '%.lua$',
    })

    for _, filepath in ipairs(files) do
        local rel_path = filepath:sub(#lua_root + 1):gsub('%.lua$', ''):gsub('[/\\]', '.')

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
                    table.insert(concat_table, entry)
                end
            else
                table.insert(concat_table, mod)
            end
            allTable = true
        else
            log.err('[load_module] Load Failed: ' .. rel_path)
        end
    end

    return concat_table
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

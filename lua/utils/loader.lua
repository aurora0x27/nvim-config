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

function M.select(module, ...)
    local fields = { ... }
    return function()
        local mod = require(module)
        for i = 1, #fields - 1 do
            mod = mod[fields[i]]
        end
        mod[fields[#fields]]()
    end
end

return M

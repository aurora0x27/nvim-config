local M = {}

---@class KeymapDecl
---@field [1] string
---@field [2] string|fun()
---@field desc? string
---@field mode? string|string[]
---@field noremap? boolean
---@field remap? boolean
---@field silent? boolean
---@field ft? string|string[]

---@class ModuleSpecDecl
---
--- meta
---@field [1] string
---@field enabled boolean
---@field kind 'inline'|'extern'
---
--- source
---@field mod? string inline module
---@field repo? string extern module -- plugin
---@field version? string|vim.VersionRange
---
---@field deps string|string[]
---
--- configuration
---@field config? fun(opt:table)|true
---@field opts? table
---@field init? fun()
---@field build? string|fun()
---
--- load trigger and misc
---@field event? string|string[]
---@field cmd? string|string[]
---@field ft? string|string[]
---@field keys? KeymapDecl|KeymapDecl[]

---@class LoaderOpt

---@param opts LoaderOpt
function M.setup(opts) end

return M

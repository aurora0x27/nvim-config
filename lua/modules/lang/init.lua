local M = {}

---@class ToolSpec
---@field name string
---@field bin? string
---@field source? "sys"|"mason"
---@field packname? string

---@class LangSpec
---@field lsp? ToolSpec
---@field formatter? ToolSpec
---@field treesitter string|string[]|true
---@field plugins? LazyPluginSpec|LazyPluginSpec[]

---@class LangOpt
---@field blacklist string
---@field whitelist string
---@field levels string

local uv = vim.uv or vim.loop

local errors = {}

---@param msg string
local function err(msg)
    table.insert(errors, msg)
end

---@param module_root string
---@return table<string, LangSpec>
local function load_specs(module_root)
    local capabilities = {}
    local lua_root = vim.fn.stdpath 'config' .. '/lua/'
    local base_dir = lua_root .. module_root:gsub('%.', '/')

    local fd = uv.fs_scandir(base_dir)
    if not fd then
        return capabilities
    end

    while true do
        local name, ty = uv.fs_scandir_next(fd)
        if not name then
            break
        end

        if ty == 'file' and name:match '%.lua$' then
            local lang_name = name:sub(1, -5)
            local mod_path = module_root .. '.' .. lang_name

            local ok, mod = pcall(require, mod_path)
            if ok and type(mod) == 'table' then
                capabilities[lang_name] = mod
            end
        end
    end

    return capabilities
end

local CAPABILITY = load_specs 'config.langs'

---@class LangFeatTbl
---@field lsp boolean
---@field fmt boolean
---@field ts boolean
LANG_FEAT_TBL_DEFAULT = { fmt = true, lsp = true, ts = true }

local function parse_to_list(str)
    if not str or str == '' then
        return {}
    end
    local t = {}
    for item in string.gmatch(str, '([^,]+)') do
        if not CAPABILITY[item] then
            err('Language `' .. item .. '` is not in CAPABILITY')
        else
            table.insert(t, vim.trim(item))
        end
    end
    return t
end

local function parse_level(tbl, str)
    if not str or str == '' then
        return
    end

    -- 1. split lang: "c:ts;rust:+lsp" -> "c:ts", "rust:+lsp"
    for block in string.gmatch(str, '([^;]+)') do
        local lang, feats_str = block:match '([^:]+):(.+)'

        if lang and feats_str then
            lang = vim.trim(lang)
            if tbl[lang] then
                -- 2. split feat "ts,+lsp,-fmt" -> "ts", "+lsp", "-fmt"
                for feat_item in string.gmatch(feats_str, '([^,]+)') do
                    feat_item = vim.trim(feat_item)
                    local first_char = feat_item:sub(1, 1)
                    if feat_item == 'full' then
                        tbl[lang] = { lsp = true, fmt = true, ts = true }
                    elseif feat_item == 'none' then
                        tbl[lang] = { lsp = false, fmt = false, ts = false }
                    else
                        local feat_name = first_char == '+' or first_char == '-' and feat_item:sub(2) or feat_item
                        if type(LANG_FEAT_TBL_DEFAULT[feat_name]) == 'nil' then
                            err(string.format('Unknown feature: %s', feat_name))
                        else
                            if first_char == '+' then
                                tbl[lang][feat_name] = true
                            elseif first_char == '-' then
                                tbl[lang][feat_name] = false
                            else
                                tbl[lang][feat_name] = true
                            end
                        end
                    end
                end
            else
                err('Language `' .. lang .. '` is not enabled')
            end
        end
    end
end

---@type table<string,LangFeatTbl>
local EnabledLangs = {}

---@type string[]
local MasonInstallList = {}

---@type string[]
local LspEnableList = {}

---@type string[]
local TSInstallList = {}

---@type LazySpec[]
local LazySpecs = {}

local function generate_lists()
    local mason_set = {}
    local ts_set = {}
    local lsp_set = {}

    ---@param lang string
    ---@param spec LangSpec
    ---@param feat LangFeatTbl
    local function process_spec(lang, spec, feat)
        if spec.plugins then
            if type(spec.plugins) == 'table' then
                table.insert(LazySpecs, spec.plugins)
            else
                err(string.format('%s.plugins is %s, expected table', lang, type(spec.plugins)))
            end
        end

        if feat.lsp and spec.lsp then
            local name = spec.lsp.name
            local install_name = spec.lsp.packname or spec.lsp.name
            if not lsp_set[name] then
                table.insert(LspEnableList, name)
                lsp_set[name] = true
            end
            if spec.lsp.source ~= 'sys' then
                if not mason_set[install_name] then
                    table.insert(MasonInstallList, install_name)
                    mason_set[install_name] = true
                end
            end
        end

        if feat.fmt and spec.formatter then
            if spec.formatter.source ~= 'sys' then
                local install_name = spec.formatter.packname or spec.formatter.name
                if not mason_set[install_name] then
                    table.insert(MasonInstallList, install_name)
                    mason_set[install_name] = true
                end
            end
        end

        local handle_ts = function(name)
            if type(name) ~= 'string' then
                err(string.format('Unknown treesitter decl type: `%s`, expected string', type(name)))
                return
            end
            if not ts_set[name] then
                table.insert(TSInstallList, name)
            end
        end

        if feat.ts and spec.treesitter then
            local ty = type(spec.treesitter)
            if ty == 'table' then
                ---@diagnostic disable:param-type-mismatch
                for _, name in ipairs(spec.treesitter) do
                    handle_ts(name)
                end
            elseif ty == 'boolean' and spec.treesitter then
                handle_ts(lang)
            elseif ty == 'string' then
                handle_ts(spec.treesitter)
            else
                err(string.format('Unknown treesitter spec type: `%s`, expected string|boolean|string[]', ty))
            end
        end
    end

    for lang, feat in pairs(EnabledLangs) do
        local spec = CAPABILITY[lang]
        if spec then
            process_spec(lang, spec, feat)
        else
            err(string.format('Language `%s` is not in CAPABILITY', lang))
        end
    end
end

---@param opt LangOpt
function M.setup(opt)
    local bl_s = opt.blacklist or ''
    local wl_s = opt.whitelist or ''
    local lvl_s = opt.levels or ''
    local bl = parse_to_list(bl_s)
    local wl = parse_to_list(wl_s)
    if #wl_s == 0 then
        wl = vim.tbl_keys(CAPABILITY)
    end
    local enabled_langs = vim.tbl_filter(function(lang_name)
        return not vim.tbl_contains(bl, lang_name)
    end, wl)
    for _, name in ipairs(enabled_langs) do
        EnabledLangs[name] = vim.deepcopy(LANG_FEAT_TBL_DEFAULT)
    end
    parse_level(EnabledLangs, lvl_s)
    generate_lists()
end

---@param lang string
---@param feat "lsp"|"fmt"|"ts"
---@return boolean
function M.is_supported(lang, feat)
    local l = EnabledLangs[lang]
    if not l then
        return false
    end
    return l[feat] == true
end

---@param lang string
---@param feat "lsp"|"fmt"|"ts"
---@return boolean
function M.has_capacity(lang, feat)
    if CAPABILITY[lang] then
        return CAPABILITY[lang][feat] and true or false
    else
        return false
    end
end

---@return LazySpec[]
function M.get_lazy_install_list()
    return LazySpecs
end

---@return string[]
function M.get_mason_install_list()
    return MasonInstallList
end

---@return string[]
function M.get_ts_install_list()
    return TSInstallList
end

---@return string[]
function M.get_lsp_enable_list()
    return LspEnableList
end

function M.get_errors()
    return errors
end

function M.get_enabled_langs()
    return EnabledLangs
end

function M.get_capabilities()
    return CAPABILITY
end

function M.emit_err()
    local tools = require 'utils.tools'
    for _, errmsg in ipairs(errors) do
        tools.err(errmsg, { title = 'LangLoader' })
    end
end

return M

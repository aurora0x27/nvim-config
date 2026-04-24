--------------------------------------------------------------------------------
-- Language module
--
-- Orchestrates the parsing of LangSpecs and Environment-driven options.
--
-- Designed as a functional data pipeline: each transformation
-- (aggregate/project) generates a new view of the underlying Schema without
-- mutating the original source. This ensures a predictable, idempotent
-- configuration state.
--
-- Initialization options are all strings, which makes them very easy to
-- concatenate and interface with environment variables.
--------------------------------------------------------------------------------
local M = {}

---@class ToolSpec
---@field name string
---@field bin? string
---@field source? "sys"|"mason"
---@field packname? string

---@class LangSpec
---@field ft? string|string[]
---@field lsp? ToolSpec
---@field formatter? ToolSpec|ToolSpec[]
---@field treesitter string|string[]|boolean
---@field plugins? string|string[]

---@class LangOpt
---@field blacklist string
---@field whitelist string
---@field levels string

---@param msg string
local function err(msg)
    vim.notify(msg, vim.log.levels.ERROR, { title = 'Lang Loader' })
end

---@param msg string
local function warn(msg)
    vim.notify(msg, vim.log.levels.WARN, { title = 'Lang Loader' })
end

local Data = {
    ---@type table<string,LangFeatTbl>
    EnabledLangs = {},

    ---@type string[]
    MasonInstallList = {},

    ---@type string[]
    LspEnableList = {},

    ---@type string[]
    TSInstallList = {},

    ---@type string[]
    TSEnableLangs = {},

    ---@type string[]
    LazyEnablePlugins = {},

    ---@type table<string,string[]>
    FormatterMap = {},

    ---@type table<string, string[]>
    LspLangMap = {},
}

local CAPABILITY = require('utils.loader').load_data_dir_as_set(
    'config.langs',
    err,
    function(set, k, v)
        ---@param ft string
        ---@param subtbl table
        local function process_ft(ft, subtbl)
            local ty = type(ft)
            if ty == 'string' then
                if set[ft] then
                    warn(
                        string.format(
                            '[Lang]: CAPABILITY[%s] is filled before, origin value will be over written',
                            ft
                        )
                    )
                end
                set[ft] = subtbl
            elseif vim.islist(ft) then
                for _, single_ft in ipairs(ft) do
                    local copy = vim.deepcopy(subtbl)

                    copy.ft = single_ft

                    if set[single_ft] then
                        warn(
                            string.format(
                                '[Lang]: CAPABILITY[%s] overwritten',
                                single_ft
                            )
                        )
                    end

                    set[single_ft] = copy
                end
            else
                err(
                    string.format(
                        '[Lang]: Item in file `%s` has a bad `ft` type, expected string or string[]',
                        table.concat(k, '/')
                    )
                )
            end
        end

        if vim.islist(v) then
            for i, subtbl in ipairs(v) do
                local ft = subtbl.ft
                if ft then
                    process_ft(ft, subtbl)
                else
                    err(
                        string.format(
                            '[Lang]: Item %d in file `%s` does not have field `ft`',
                            table.concat(k, '/'),
                            i
                        )
                    )
                end
            end
        else
            local key = v.ft or k[#k]
            process_ft(key, v)
        end
    end
)

---@class LangFeatTbl
---@field lsp boolean
---@field fmt boolean
---@field ts boolean
---@field plg boolean

local LANG_FEAT_TBL_DEFAULT = { fmt = true, lsp = true, ts = true, plg = true }

local function parse_level(tbl, str)
    if not str or str == '' then
        return
    end

    -- 1. split lang: "c:ts;rust:+lsp" -> "c:ts", "rust:+lsp"
    for block in string.gmatch(str, '([^;]+)') do
        local lang, feats_str = block:match '([^:]+):(.+)'

        -- 2. split feat "ts,+lsp,-fmt" -> "ts", "+lsp", "-fmt"
        if lang and feats_str then
            lang = vim.trim(lang)
            local mask = require('utils.misc').process_feat_mask(
                feats_str,
                LANG_FEAT_TBL_DEFAULT,
                function(msg)
                    warn(string.format('[%s]: %s', lang, msg))
                end
            )
            if lang == 'all' then
                for _, feat in pairs(tbl) do
                    for k, v in pairs(mask) do
                        feat[k] = v
                    end
                end
            elseif tbl[lang] then
                for k, v in pairs(mask) do
                    tbl[lang][k] = v
                end
            else
                warn('Language `' .. lang .. '` is not enabled')
            end
        end
    end
end

local function generate_lists()
    local mason_set = {}
    local ts_set = {}

    ---@param lang string
    ---@param spec LangSpec
    ---@param feat LangFeatTbl
    local function process_spec(lang, spec, feat)
        if feat.plg and spec.plugins then
            if type(spec.plugins) == 'string' then
                table.insert(Data.LazyEnablePlugins, spec.plugins)
            elseif type(spec.plugins) == 'table' then
                ---@diagnostic disable:param-type-mismatch
                for _, i in ipairs(spec.plugins) do
                    table.insert(Data.LazyEnablePlugins, i)
                end
            else
                err(
                    string.format(
                        '%s.plugins is %s, expected string',
                        lang,
                        type(spec.plugins)
                    )
                )
            end
        end

        if feat.lsp and spec.lsp then
            local name = spec.lsp.name
            local install_name = spec.lsp.packname or spec.lsp.name
            if not Data.LspLangMap[name] then
                table.insert(Data.LspEnableList, name)
                Data.LspLangMap[name] = { lang }
            else
                table.insert(Data.LspLangMap[name], lang)
            end
            if spec.lsp.source ~= 'sys' then
                if not mason_set[install_name] then
                    table.insert(Data.MasonInstallList, install_name)
                    mason_set[install_name] = true
                end
            end
        end

        if feat.fmt and spec.formatter then
            local tbl = {}
            local function process_single_fmt_decl(decl)
                table.insert(tbl, decl.name)
                if decl.source ~= 'sys' then
                    local install_name = decl.packname or decl.name
                    if not mason_set[install_name] then
                        table.insert(Data.MasonInstallList, install_name)
                        mason_set[install_name] = true
                    end
                end
            end
            if vim.islist(spec.formatter) then
                for _, decl in ipairs(spec.formatter) do
                    process_single_fmt_decl(decl)
                end
            else
                process_single_fmt_decl(spec.formatter)
            end
            Data.FormatterMap[lang] = tbl
        end

        local handle_ts = function(name)
            if type(name) ~= 'string' then
                err(
                    string.format(
                        'Unknown treesitter decl type: `%s`, expected string',
                        type(name)
                    )
                )
                return
            end
            if not ts_set[name] then
                table.insert(Data.TSInstallList, name)
            end
        end

        if feat.ts and type(spec.treesitter) ~= 'nil' then
            local ty = type(spec.treesitter)
            if ty == 'table' then
                table.insert(Data.TSEnableLangs, lang)
                ---@diagnostic disable:param-type-mismatch
                for _, name in ipairs(spec.treesitter) do
                    handle_ts(name)
                end
            elseif ty == 'boolean' then
                if spec.treesitter then
                    table.insert(Data.TSEnableLangs, lang)
                    handle_ts(lang)
                end
            elseif ty == 'string' then
                table.insert(Data.TSEnableLangs, lang)
                handle_ts(spec.treesitter)
            else
                err(
                    string.format(
                        'Unknown treesitter spec type: `%s`, expected string or boolean or string[]',
                        ty
                    )
                )
            end
        end
    end

    for lang, feat in pairs(Data.EnabledLangs) do
        local spec = CAPABILITY[lang]
        if spec then
            process_spec(lang, spec, feat)
        else
            warn(string.format('Language `%s` is not in CAPABILITY', lang))
        end
    end
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
        if name ~= 'all' and CAPABILITY[name] == nil then
            warn(string.format('Item `%s` is not in CAPABILITY', name))
        end
        res[name] = true
    end
    return res
end

---@param opt LangOpt
function M.setup(opt)
    local bl_s = opt.blacklist or ''
    local wl_s = opt.whitelist or ''
    local lvl_s = opt.levels or ''
    local all_lang_keys = vim.tbl_keys(CAPABILITY)
    local wl_set = parse_to_set(wl_s)
    local bl_set = parse_to_set(bl_s)
    local has_whitelist = #wl_s > 0 and wl_s ~= 'all'
    for _, name in ipairs(all_lang_keys) do
        local in_wl = wl_set[name]
        local in_bl = bl_set['all'] or bl_set[name]
        local is_enabled
        if has_whitelist then
            is_enabled = in_wl
        else
            is_enabled = not in_bl
        end
        if has_whitelist and in_wl and in_bl then
            is_enabled = true
        end
        if is_enabled then
            Data.EnabledLangs[name] = vim.deepcopy(LANG_FEAT_TBL_DEFAULT)
        end
    end
    parse_level(Data.EnabledLangs, lvl_s)
    generate_lists()
end

---@param lang string
---@param feat "lsp"|"fmt"|"ts"|"plg"
---@return boolean
function M.is_supported(lang, feat)
    local l = Data.EnabledLangs[lang]
    if not l then
        return false
    end
    return l[feat] == true
end

---@param lang string
---@param feat "lsp"|"fmt"|"ts"
---@return boolean
function M.has_capability(lang, feat)
    if CAPABILITY[lang] then
        return CAPABILITY[lang][feat] and true or false
    else
        return false
    end
end

---@param name string
---@param spec LazySpec
function M.mask_lazy_spec(name, spec)
    if vim.tbl_contains(Data.LazyEnablePlugins, name) then
        spec.enabled = true
    end
end

function M.get_lazy_enable_lists()
    return Data.LazyEnablePlugins
end

---@return string[]
function M.get_mason_install_list()
    return Data.MasonInstallList
end

---@return string[]
function M.get_ts_install_list()
    return Data.TSInstallList
end

---@return string[]
function M.get_ts_enable_langs()
    return Data.TSEnableLangs
end

---@return string[]
function M.get_lsp_enable_list()
    return Data.LspEnableList
end

---@return table<string,string[]>
function M.get_formatter_map()
    return Data.FormatterMap
end

function M.get_enabled_langs()
    return Data.EnabledLangs
end

function M.get_capabilities()
    return CAPABILITY
end

---@param lsp string
---@return string[] langs
function M.lsp_get_ft(lsp)
    return Data.LspLangMap[lsp] or {}
end

-- export as global
_G.Lang = M

return M

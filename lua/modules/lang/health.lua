local M = {}
local lang_mod = require 'modules.lang'

local function pad(s, width)
    return s .. string.rep(' ', width - #s)
end

function M.check()
    local enabled = lang_mod.get_enabled_langs()
    local caps = lang_mod.get_capabilities()

    -- Table head
    -- L: LSP, F: Formatter, T: Treesitter, P: Plugins
    local title = 'Language State'
    vim.health.start(pad(title, 23) .. 'L F T P')

    local all_langs = {}
    for k in pairs(caps) do
        table.insert(all_langs, k)
    end
    table.sort(all_langs)

    for _, lang in ipairs(all_langs) do
        local spec = caps[lang]
        local feat = enabled[lang]

        local function get_stat(has_cap, is_enabled)
            if has_cap then
                if is_enabled then
                    return ''
                end
                return 'x'
            end
            return '.'
        end

        local l_stat = get_stat(spec.lsp, feat and feat.lsp)
        local f_stat = get_stat(spec.formatter, feat and feat.fmt)
        local t_stat = get_stat(spec.treesitter, feat and feat.ts)
        local p_stat = get_stat(spec.plugins, feat ~= nil)

        local row = string.format('%s %s %s %s %s', pad(lang, 20), l_stat, f_stat, t_stat, p_stat)

        if feat then
            vim.health.info(row)
        else
            vim.health.info(row .. ' (Disabled)')
        end
    end

    vim.health.start 'Legend: [L]SP, [F]ormatter, [T]reesitter, [P]lugins | ``: Active, `x`: Mapped but Disabled, `.`: No Capacity'

    vim.health.start 'Resource Lists (Final Output)'

    local lists = {
        { name = 'Mason Install', data = lang_mod.get_mason_install_list() },
        { name = 'Treesitter Install', data = lang_mod.get_ts_install_list() },
        { name = 'LSP Enabled', data = lang_mod.get_lsp_enable_list() },
    }

    for _, list in ipairs(lists) do
        if #list.data > 0 then
            vim.health.start(list.name .. ':')
            for _, item in ipairs(list.data) do
                vim.health.info(item)
            end
        else
            vim.health.start(list.name .. ': (Empty)')
        end
    end

    local errs = lang_mod.get_errors()
    if #errs > 0 then
        vim.health.start 'Diagnostics'
        for _, e in ipairs(errs) do
            vim.health.error(e)
        end
    end
end

return M

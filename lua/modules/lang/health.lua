local M = {}
local lang_mod = require 'modules.lang'

local pad = require('utils.misc').pad

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

        local row = string.format(
            '%s %s %s %s %s',
            pad(lang, 20),
            l_stat,
            f_stat,
            t_stat,
            p_stat
        )

        if feat then
            vim.health.info(row)
        else
            vim.health.info(row .. ' (Disabled)')
        end
    end

    vim.health.start 'Legend: [L]SP, [F]ormatter, [T]reesitter, [P]lugins'
    vim.health.start [['': Active, 'x': Mapped but Disabled, '.': No Capacity]]

    vim.health.start 'Resource Lists (Final Output)'

    local lists = {
        { name = 'Mason Install', data = lang_mod.get_mason_install_list() },
        { name = 'LazySpecs', data = lang_mod.get_lazy_enable_lists() },
        { name = 'Treesitter Install', data = lang_mod.get_ts_install_list() },
    }

    local maps = {
        { name = 'Formatter Map', data = lang_mod.get_formatter_map() },
    }

    for _, map in ipairs(maps) do
        vim.health.start(map.name .. ':')
        for key, val in pairs(map.data) do
            if type(val) ~= 'string' then
                vim.health.info(key .. ' : ' .. vim.inspect(val))
            else
                vim.health.info(key .. ' : ' .. val)
            end
        end
    end

    vim.health.start('Enabled Lsp')
    local enabled_lsp = lang_mod.get_lsp_enable_list()
    for _, lsp in ipairs(enabled_lsp) do
        vim.health.info(lsp .. ' : ' .. vim.inspect(lang_mod.lsp_get_ft(lsp)))
    end

    for _, list in ipairs(lists) do
        if #list.data > 0 then
            vim.health.start(list.name .. ':')
            for _, item in ipairs(list.data) do
                vim.health.info(tostring(item))
            end
        else
            vim.health.start(list.name .. ': (Empty)')
        end
    end
end

return M

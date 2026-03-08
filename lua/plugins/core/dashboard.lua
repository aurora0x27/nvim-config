--------------------------------------------------------------------------------
-- Dash board config
--------------------------------------------------------------------------------

---@type LazyPluginSpec
local Dashboard = {
    'goolord/alpha-nvim',
    event = { 'VimEnter' },
    config = function()
        local alpha = require 'alpha'
        local dashboard = require 'alpha.themes.dashboard'
        local set_global_hl = require 'utils.misc'.set_global_hl
        local colors = require 'config.assets.misc'.ColorAlias

        set_global_hl('AlphaHeader', colors.blue)
        set_global_hl('AlphaButtons', colors.green)
        set_global_hl('AlphaShortcut', colors.pink, nil, true, true)
        set_global_hl('AlphaFooter', colors.yellow)

        local logos = require 'config.assets.logo'

        local art = logos[require('modules.profile').dashboard_art_name]

        dashboard.section.header.val = art or logos['Ayanami Rei']

        dashboard.section.header.opts = {
            position = 'center',
            hl = 'AlphaHeader',
        }

        dashboard.opts.opts = {
            number = false,
            relativenumber = false,
        }

        --- @param sc string
        --- @param txt string
        --- @param keybind string? optional
        --- @param keybind_opts table? optional
        local function button(sc, txt, keybind, keybind_opts)
            local sc_after = sc:gsub('%s', '')
            local opts = {
                position = 'center',
                shortcut = sc,
                cursor = 3,
                width = 50,
                align_shortcut = 'right',
                hl = 'AlphaButtons',
                hl_shortcut = 'AlphaShortcut',
            }
            if nil ~= keybind then
                keybind_opts = vim.F.if_nil(
                    keybind_opts,
                    { noremap = true, silent = true, nowait = true }
                )
                opts.keymap = { 'n', sc_after, keybind, keybind_opts }
            end
            local function on_press()
                local key = vim.api.nvim_replace_termcodes(
                    sc_after .. '<Ignore>',
                    true,
                    false,
                    true
                )
                vim.api.nvim_feedkeys(key, 't', false)
            end
            return {
                type = 'button',
                val = txt,
                on_press = on_press,
                opts = opts,
            }
        end

        dashboard.section.buttons.val = {
            button(
                '<leader> n  ',
                '  [N]ew File',
                '<cmd>ene <BAR> startinsert<CR>',
                {
                    noremap = true,
                    silent = true,
                    nowait = true,
                    desc = '[N]ew file',
                }
            ),
            button('<leader> f f', '  Find [F]ile'),
            button('<leader> f o', '󰈙  Recent/[O]ld Files'),
            button('<leader> f w', '󰈭  [W]ildcard Grep'),
            button('<leader> s l', '  Last [S]ession'),
            button('<leader> P  ', '  [P]lugins', '<cmd>Lazy<cr>'),
        }

        dashboard.section.footer.val = 'Loading plugins...'
        dashboard.section.footer.opts.hl = 'AlphaFooter'

        local head_butt_padding = 2
        local occu_height = #dashboard.section.header.val
            + 2 * #dashboard.section.buttons.val
            + head_butt_padding
        local header_padding =
            math.max(0, math.ceil((vim.fn.winheight(0) - occu_height) * 0.5))
        local foot_butt_padding = 1

        dashboard.config.layout = {
            { type = 'padding', val = header_padding },
            dashboard.section.header,
            { type = 'padding', val = head_butt_padding },
            dashboard.section.buttons,
            { type = 'padding', val = foot_butt_padding },
            dashboard.section.footer,
        }

        if vim.o.filetype == 'lazy' then
            vim.cmd.close()
            vim.api.nvim_create_autocmd('User', {
                once = true,
                pattern = 'AlphaReady',
                callback = function()
                    require('lazy').show()
                end,
            })
        end

        alpha.setup(dashboard.opts)

        local function footer()
            local lazy_stats = require('lazy').stats()
            local plugin_load = lazy_stats.loaded
            local plugin_count = lazy_stats.count
            local load_time = lazy_stats.startuptime

            -- Windows cannot handle unicode icons :(
            local date = os.date '%Y-%m-%d'
            local time = os.date '%H:%M:%S'
            local datetime = ' ' .. date .. '   ' .. time

            return string.format(
                '⚡ %d/%d plugins loaded in %.2fms  |  %s',
                plugin_load,
                plugin_count,
                load_time,
                datetime
            )
        end

        vim.api.nvim_create_autocmd('User', {
            once = true,
            pattern = 'LazyVimStarted',
            callback = function()
                dashboard.section.footer.val = footer()
                pcall(vim.cmd.AlphaRedraw)
            end,
        })

        vim.cmd [[ autocmd FileType alpha setlocal nofoldenable ]]
    end,
}

return Dashboard

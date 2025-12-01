-- Dash board config

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local Dashboard = {
    'goolord/alpha-nvim',
    event = { 'VimEnter' },
    init = false,
    requires = { 'kyazdani42/nvim-web-devicons' },
    config = function()
        local alpha = require 'alpha'
        local dashboard = require 'alpha.themes.dashboard'

        local function footer()
            local lazy_stats = require('lazy').stats()
            local plugin_load = lazy_stats.loaded
            local plugin_count = lazy_stats.count
            local load_time = lazy_stats.startuptime
            local datetime = os.date ' %d-%m-%Y   %H:%M:%S'

            return string.format(
                '⚡ %d/%d plugins loaded in %.2fms  |  %s',
                plugin_load,
                plugin_count,
                load_time,
                datetime
            )
        end

        local logos = require 'config.alpha.logo'

        -- NOTE: lua index from `1`, not `0`
        if vim.env.NVIM_DASHBOARD_ART_NAME then
            dashboard.section.header.val = logos[vim.env.NVIM_DASHBOARD_ART_NAME]
        else
            dashboard.section.header.val = logos['Ayanami Rei']
        end

        dashboard.section.header.opts = {
            position = 'center',
            hl = 'Function',
        }

        dashboard.opts.opts = {
            number = false,
            relativenumber = false,
        }

        dashboard.section.buttons.val = {
            dashboard.button(
                'SPC n  ',
                '  [N]ew File',
                ':ene <BAR> startinsert<CR>',
                { noremap = true, silent = true, nowait = true, desc = '[N]ew file' }
            ),
            dashboard.button('SPC f f', '  Find [F]ile'),
            dashboard.button('SPC f o', '󰈙  Recent/[O]ld Files'),
            dashboard.button('SPC f w', '󰈭  [W]ildcard Grep'),
            dashboard.button('SPC s l', '  Last [S]ession'),
        }

        for _, button in ipairs(dashboard.section.buttons.val) do
            button.opts = button.opts or {}
            button.opts.hl = 'DiagnosticOk'
            button.opts.hl_shortcut = 'Special'
        end

        dashboard.section.footer.val = 'Loading plugins...'
        dashboard.section.footer.opts.hl = 'Type'

        local lines = vim.o.lines

        dashboard.config.layout = {
            { type = 'padding', val = math.floor(lines / 5) },
            dashboard.section.header,
            { type = 'padding', val = 2 },
            dashboard.section.buttons,
            { type = 'padding', val = 1 },
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

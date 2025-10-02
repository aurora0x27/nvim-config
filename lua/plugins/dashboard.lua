-- Dash board config

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local Dashboard = {
    'goolord/alpha-nvim',
    lazy = false,
    priority = 2000,
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

        -- Update alpha after loaded
        vim.api.nvim_create_autocmd('UIEnter', {
            callback = function()
                dashboard.section.footer.val = footer()
                require('alpha').redraw()
            end,
        })

        local logos = {
            ['Ayanami Rei'] = {
                '⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿',
                '⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⣠⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿',
                '⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣡⣾⣿⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿⣿⣟⠻⣿⣿⣿⣿⣿⣿⣿⣿',
                '⣿⣿⣿⣿⣿⣿⣿⣿⡿⢫⣷⣿⣿⣿⣿⣿⣿⣿⣾⣯⣿⡿⢧⡚⢷⣌⣽⣿⣿⣿⣿⣿⣶⡌⣿⣿⣿⣿⣿⣿',
                '⣿⣿⣿⣿⣿⣿⣿⣿⠇⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣮⣇⣘⠿⢹⣿⣿⣿⣿⣿⣻⢿⣿⣿⣿⣿⣿',
                '⣿⣿⣿⣿⣿⣿⣿⣿⠀⢸⣿⣿⡇⣿⣿⣿⣿⣿⣿⣿⣿⡟⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣻⣿⣿⣿⣿',
                '⣿⣿⣿⣿⣿⣿⣿⡇⠀⣬⠏⣿⡇⢻⣿⣿⣿⣿⣿⣿⣿⣷⣼⣿⣿⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⢻⣿⣿⣿⣿',
                '⣿⣿⣿⣿⣿⣿⣿⠀⠈⠁⠀⣿⡇⠘⡟⣿⣿⣿⣿⣿⣿⣿⣿⡏⠿⣿⣟⣿⣿⣿⣿⣿⣿⣿⣿⣇⣿⣿⣿⣿',
                '⣿⣿⣿⣿⣿⣿⡏⠀⠀⠐⠀⢻⣇⠀⠀⠹⣿⣿⣿⣿⣿⣿⣩⡶⠼⠟⠻⠞⣿⡈⠻⣟⢻⣿⣿⣿⣿⣿⣿⣿',
                '⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⢿⠀⡆⠀⠘⢿⢻⡿⣿⣧⣷⢣⣶⡃⢀⣾⡆⡋⣧⠙⢿⣿⣿⣟⣿⣿⣿⣿',
                '⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⡥⠂⡐⠀⠁⠑⣾⣿⣿⣾⣿⣿⣿⡿⣷⣷⣿⣧⣾⣿⣿⣿⣿⣿⣿⣿',
                '⣿⣿⡿⣿⣍⡴⠆⠀⠀⠀⠀⠀⠀⠀⠀⣼⣄⣀⣷⡄⣙⢿⣿⣿⣿⣿⣯⣶⣿⣿⢟⣾⣿⣿⢡⣿⣿⣿⣿⣿',
                '⣿⡏⣾⣿⣿⣿⣷⣦⠀⠀⠀⢀⡀⠀⠀⠠⣭⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⣡⣾⣿⣿⢏⣾⣿⣿⣿⣿⣿',
                '⣿⣿⣿⣿⣿⣿⣿⣿⡴⠀⠀⠀⠀⠀⠠⠀⠰⣿⣿⣿⣷⣿⠿⠿⣿⣿⣭⡶⣫⠔⢻⢿⢇⣾⣿⣿⣿⣿⣿⣿',
                '⣿⣿⣿⡿⢫⣽⠟⣋⠀⠀⠀⠀⣶⣦⠀⠀⠀⠈⠻⣿⣿⣿⣾⣿⣿⣿⣿⡿⣣⣿⣿⢸⣾⣿⣿⣿⣿⣿⣿⣿',
                '⡿⠛⣹⣶⣶⣶⣾⣿⣷⣦⣤⣤⣀⣀⠀⠀⠀⠀⠀⠀⠉⠛⠻⢿⣿⡿⠫⠾⠿⠋⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿',
                '⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣀⡆⣠⢀⣴⣏⡀⠀⠀⠀⠉⠀⠀⢀⣠⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿',
                '⠿⠛⠛⠛⠛⠛⠛⠻⢿⣿⣿⣿⣿⣯⣟⠷⢷⣿⡿⠋⠀⠀⠀⠀⣵⡀⢠⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿',
                '⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠛⢿⣿⣿⠂⠀⠀⠀⠀⠀⢀⣽⣿⣿⣿⣿⣿⣿⣿⣍⠛⠿⣿⣿⣿⣿⣿⣿',
            },
            ['Default'] = {
                ' ⣇⣿⠘⣿⣿⣿⡿⡿⣟⣟⢟⢟⢝⠵⡝⣿⡿⢂⣼⣿⣷⣌⠩⡫⡻⣝⠹⢿⣿⣷ ',
                ' ⡆⣿⣆⠱⣝⡵⣝⢅⠙⣿⢕⢕⢕⢕⢝⣥⢒⠅⣿⣿⣿⡿⣳⣌⠪⡪⣡⢑⢝⣇ ',
                ' ⡆⣿⣿⣦⠹⣳⣳⣕⢅⠈⢗⢕⢕⢕⢕⢕⢈⢆⠟⠋⠉⠁⠉⠉⠁⠈⠼⢐⢕⢽ ',
                ' ⡗⢰⣶⣶⣦⣝⢝⢕⢕⠅⡆⢕⢕⢕⢕⢕⣴⠏⣠⡶⠛⡉⡉⡛⢶⣦⡀⠐⣕⢕ ',
                ' ⡝⡄⢻⢟⣿⣿⣷⣕⣕⣅⣿⣔⣕⣵⣵⣿⣿⢠⣿⢠⣮⡈⣌⠨⠅⠹⣷⡀⢱⢕ ',
                ' ⡝⡵⠟⠈⢀⣀⣀⡀⠉⢿⣿⣿⣿⣿⣿⣿⣿⣼⣿⢈⡋⠴⢿⡟⣡⡇⣿⡇⡀⢕ ',
                ' ⡝⠁⣠⣾⠟⡉⡉⡉⠻⣦⣻⣿⣿⣿⣿⣿⣿⣿⣿⣧⠸⣿⣦⣥⣿⡇⡿⣰⢗⢄ ',
                ' ⠁⢰⣿⡏⣴⣌⠈⣌⠡⠈⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣬⣉⣉⣁⣄⢖⢕⢕⢕ ',
                ' ⡀⢻⣿⡇⢙⠁⠴⢿⡟⣡⡆⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣵⣵⣿ ',
                ' ⡻⣄⣻⣿⣌⠘⢿⣷⣥⣿⠇⣿⣿⣿⣿⣿⣿⠛⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿ ',
                ' ⣷⢄⠻⣿⣟⠿⠦⠍⠉⣡⣾⣿⣿⣿⣿⣿⣿⢸⣿⣦⠙⣿⣿⣿⣿⣿⣿⣿⣿⠟ ',
                ' ⡕⡑⣑⣈⣻⢗⢟⢞⢝⣻⣿⣿⣿⣿⣿⣿⣿⠸⣿⠿⠃⣿⣿⣿⣿⣿⣿⡿⠁⣠ ',
                ' ⡝⡵⡈⢟⢕⢕⢕⢕⣵⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣿⣿⣿⣿⣿⠿⠋⣀⣈⠙ ',
                ' ⡝⡵⡕⡀⠑⠳⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⢉⡠⡲⡫⡪⡪⡣ ',
            },
            ['Vscode'] = {
                '⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣋⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿',
                '⣿⣿⡏⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⡌⢰⠋⢳⣝⠿⢡⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⠙⣿⣿⣿⣿⣿⣿⣿⣿⣿',
                '⣿⣿⡇⣿⢿⣿⣿⣿⣿⣿⣿⡿⠿⠇⠀⠀⠀⠙⢧⢸⡿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢀⣿⣿⣿⣿⣿⣿⣿⣿⣿',
                '⣿⣿⣿⣶⢸⣿⣿⣿⣿⣿⣿⣿⠀⠄⠀⠀⠀⠀⠀⠂⣴⣿⣿⣿⣿⣿⣿⣿⠋⣠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿',
                '⣿⣿⣿⣿⢸⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⢀⠔⣠⣾⣿⣿⣿⣿⣿⣿⠟⣡⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿',
                '⣿⣿⣿⣿⢸⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⣡⣾⣿⣿⣿⣿⣿⣿⠟⢁⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿',
                '⣿⣿⣿⣿⢸⣿⣿⣿⣿⣿⣿⣿⠀⡀⢀⣼⣿⣿⣿⣿⣿⣿⡿⠋⠀⢷⣝⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿',
                '⣿⣿⢟⣵⢸⣿⣿⣿⣿⣿⣿⡿⢀⣴⣿⣿⣿⣿⣿⣿⣿⠋⠀⠀⠀⠀⠙⢷⡙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿',
                '⡟⣡⠟⠁⢸⣿⣿⣿⣿⣿⣿⣷⣿⣿⣿⣿⣿⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠙⢦⡻⣿⣿⣿⣿⣿⣿⣿⣿⣿',
                '⣷⣄⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿',
                '⣿⣿⣷⣄⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⡿⠿⠿⣿⣿⣿⣿⣿⣿',
                '⣿⣿⣿⣿⢸⣿⣿⣿⣿⣿⣿⣿⡿⠛⠋⠀⠂⠀⠀⠀⠀⠀⢀⠀⠀⠀⠰⣿⣿⠿⠛⠂⣽⡇⣼⠟⠛⠛⠻⣿',
                '⣿⣿⣿⣿⢸⣿⣿⣿⣿⣿⣿⡟⣰⡟⠛⠋⡀⢠⣾⠛⠛⠃⢠⡾⢛⢻⣷⠸⢡⡾⠟⢿⡿⠰⢡⡿⠛⢻⡷⢸',
                '⣿⣿⣿⣿⢸⣿⣿⣿⣿⣿⡟⠀⠻⢷⣶⡄⢀⣿⠃⠈⠀⢀⣿⢡⡟⣸⡏⢠⣿⢡⠇⣾⢃⢃⣿⠷⠶⠾⢃⣾',
                '⣿⣿⣿⣿⢸⣿⣿⣿⡿⢋⠀⣈⣀⣠⣿⠃⢸⣿⣄⣀⡄⢸⣧⣘⣱⡟⡀⢸⣧⣬⣼⡏⣼⢸⣿⣬⣭⡌⣿⣿',
                '⣿⣿⣿⣿⣮⣛⣛⣋⣠⣾⣌⣉⡉⠉⠁⠀⠀⠉⢉⣉⣼⣦⣍⣉⣥⣾⣷⣌⣉⣡⣉⣁⣼⣬⣉⣉⣉⣴⣿⣿',
                '⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⣠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿',
                '⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿',
            },
            ['Tokamak original'] = {
                '',
                '         ⠉⠛⠛⠿⠿⡿⠿⠿⠿⠿⠿⠿⢿⠿⠿⠛⠛⠉',
                ' ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠓⠒⠦⠀⠀⠀⠀⠀⠀⠀⠀⠴⠒⠚⠉',
                '',
                ' ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠤⠶⠶⠶⠶⠶⠶⠶⠶⠤',
                '',
                ' ⣧⠀⠹⡄⠀⠀⠀⠀⠀⢠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡄⠀⠀⠀⠀⠀⢠⠏⠀⣼',
                ' ⠘⣷⡀⠘⣆⠀⠀⠀⠀⠈⢧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡼⠁⠀⠀⠀⠀⣰⠃⢀⣾⠃',
                ' ⠀⠀⠹⡀⠈⢧⠀⠀⠀⠀⠀⢳⡀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡞⠀⠀⠀⠀⠀⡼⠁⢀⠏',
                ' ⠀⠀⠀⠘⣄⠀⢳⡀⠀⠀⠀⠀⠹⡄⠀⠀⠀⠀⠀⠀⢠⠏⠀⠀⠀⠀⢀⡞⠀⣠⠃',
                ' ⠀⠀⠀⠀⠈⢧⠀⠹⡄⠀⠀⠀⠀⠈⠀⠀⠀⠀  ⠁ ⠀⠀⠀⢠⠏⠀⡼⠁',
                ' ⠀⠀⠀⠀⠀⠀⠳⠀⠘⣦⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣴⠃⠀⠞',
                ' ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⡿⠁',
                ' ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⡀⠀⠀⠀⠀⠀⠀⢀⣿⡟',
                ' ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⠀⠀⠀⠀⠀⠀⠀⠀⠏',
            },
            ['Tokamak collapse'] = {
                '',
                ' ⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠛⠿⠞⡿⠷⠿⠿⠟⠷⠹⠟⠒⠕⠔⠂⠉⠂⠐⠂',
                ' ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠓⠂⠒⠦⠂⠒⠀⠀⠀⠀⠀⠴⠒⠔ ⠂⠉',
                '',
                ' ⠀⠀⠀⠀⠀⠀⠀ ⠀ ⠀ ⣀⣠⣤⠔ ⠤⠂⠒⠤⠠⣀ ⠤⠠',
                '',
                ' ⣧⠀⠹⡄⠡⠒⠀⠂⠀⠀⢀⠀⣈⢀  ⠀⠀⠀ ⠀⠀⠀⠀⠠⠀⠉ ⠒⠀⠀⠠⡐ ⡌⠠⠒⠀',
                ' ⠘⠕⡀⠘⣆⠤⠠⠀⠀⠈⢧⠤⢀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀ ⡼⠁⠤⠀⠀⠀⣰⠃ ⢀⠶⠐ ',
                ' ⠀⠀⠡⡄⠈⠡⠀ ⠀⠀⠀⢳⡀⠀⣀⠀⠀⠀⠀⠀⠀⠀⢀⡊⠂⠀⠀⠀⠀⡼⠁⢠⠏⠈ ⠉⠐⠈⠉',
                ' ⠀⠀⠀⠘⡣⠀⢳⡀⢀⣀⠀⠀⠡⡅ ⠀⠂⠀ ⠀⠀⢠⡢ ⠤⠀⠀⡊⠀  ⡐⠃⠉ ⠒',
                '  ⠀⠀⠀⠈⢧⠀⠹⡄⠀⠀⠀⠀⠈ ⠂⠉⠀⠀ ⠐⠁ ⠀⠀⢠⠏ ⡼⠁⠉',
                '   ⠀⠀⠀⠀⠳⠀⠘⣦⣄⠀⠀⠀⠀⠀  ⠀⠀⠀  ⠀⣠⡢⠃⠞',
                ' ⠀  ⠀ ⠀⠀⠀ ⠈ ⠕⠉⠀⢀⣀⠠⠀⠀⠀ ⠀⠠⠠⡠⠛⠁⠉ ⠉',
                ' ⠀⠀  ⠀⠀⠀⠀  ⠀⢻⡀⠂⠀  ⠀⠀ ⢀⢌⠋⡠ ⠒',
                ' ⠀⠀⠀  ⠀⠀⠀⠀⠀⠀⠀ ⠙⠠ ⠒  ⠀⠀⡰⠏ ⠒',
            },
        }

        -- NOTE: lua index from `1`, not `0`
        dashboard.section.header.val = logos['Vscode']

        dashboard.section.header.opts = {
            position = 'center',
            hl = 'Function',
        }

        dashboard.opts.opts = {
            number = false,
            relativenumber = false,
        }

        dashboard.section.buttons.val = {
            dashboard.button('SPC n  ', '  New File', ':ene <BAR> startinsert<CR>'),
            dashboard.button('SPC f f', '  Find File', ':Telescope find_files<CR>'),
            dashboard.button('SPC f o', '󰈙  Recents', ':Telescope oldfiles<CR>'),
            dashboard.button('SPC f w', '󰈭  Find Word', ':Telescope live_grep<CR>'),
            dashboard.button('SPC S l', '  Last Session', function()
                local oldfiles = vim.v.oldfiles
                for _, file in ipairs(oldfiles) do
                    if vim.fn.filereadable(file) == 1 then
                        vim.cmd('edit ' .. vim.fn.fnameescape(file))
                        return
                    end
                end
                vim.notify('No previous file found in v:oldfiles', vim.log.levels.WARN)
            end),
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

        alpha.setup(dashboard.opts)

        vim.cmd [[ autocmd FileType alpha setlocal nofoldenable ]]
    end,
}

return Dashboard

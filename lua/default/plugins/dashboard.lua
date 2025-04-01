-- Dash board config
-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- using snack as dashboard
return {
    'folke/snacks.nvim',
    config = function()

        require('snacks').setup {
            styles = {
              notification = { border = 'single' },
              notification_history = { border = 'single', width = 0.9, height = 0.9, minimal = true },
              snacks_image = {
                border = 'single',
              },
            },
            indent = {
                indent = {
                    char = ' ',
                    only_scope = true,
                    only_current = true,
                    hl = {
                        'SnacksIndent1',
                        'SnacksIndent2',
                        'SnacksIndent3',
                        'SnacksIndent4',
                        'SnacksIndent5',
                        'SnacksIndent6',
                        'SnacksIndent7',
                        'SnacksIndent8',
                    },
                },
                animate = {
                    duration = {
                        step = 10,
                        duration = 100,
                    },
                },
                scope = {
                    enabled = false, -- enable highlighting the current scope
                    priority = 200,
                    char = '┊',
                    underline = false, -- underline the start of the scope
                    only_current = true, -- only show scope in the current window
                    hl = {
                        'SnacksIndent1',
                        'SnacksIndent2',
                        'SnacksIndent3',
                        'SnacksIndent4',
                        'SnacksIndent5',
                        'SnacksIndent6',
                        'SnacksIndent7',
                        'SnacksIndent8',
                    },
                },
            },  
            lazygit = {},
            notifier = {},
            bufdelete = {},
            dashboard = {
                preset = {
                    keys = {
                        {
                            icon = '󰈞 ',
                            key = 'f',
                            desc = 'Find files',
                            action = function()
                                Snacks.picker.files()
                            end,
                        },
                        {
                            icon = ' ',
                            key = 'o',
                            desc = 'Find history',
                            action = function()
                                Snacks.picker.recent()
                            end,
                        },
                        { icon = ' ', key = 'e', desc = 'New file', action = ':enew' },
                        { icon = '󰒲 ', key = 'L', desc = 'Lazy', action = ':Lazy', enabled = package.loaded.lazy ~= nil },
                        { icon = ' ', key = 'P', desc = 'Lazy Profile', action = ':Lazy profile', enabled = package.loaded.lazy ~= nil },
                        { icon = ' ', key = 'M', desc = 'Mason', action = ':Mason', enabled = package.loaded.lazy ~= nil },
                        { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
                    },
                    header = [[
⣇⣿⠘⣿⣿⣿⡿⡿⣟⣟⢟⢟⢝⠵⡝⣿⡿⢂⣼⣿⣷⣌⠩⡫⡻⣝⠹⢿⣿⣷
⡆⣿⣆⠱⣝⡵⣝⢅⠙⣿⢕⢕⢕⢕⢝⣥⢒⠅⣿⣿⣿⡿⣳⣌⠪⡪⣡⢑⢝⣇
⡆⣿⣿⣦⠹⣳⣳⣕⢅⠈⢗⢕⢕⢕⢕⢕⢈⢆⠟⠋⠉⠁⠉⠉⠁⠈⠼⢐⢕⢽
⡗⢰⣶⣶⣦⣝⢝⢕⢕⠅⡆⢕⢕⢕⢕⢕⣴⠏⣠⡶⠛⡉⡉⡛⢶⣦⡀⠐⣕⢕
⡝⡄⢻⢟⣿⣿⣷⣕⣕⣅⣿⣔⣕⣵⣵⣿⣿⢠⣿⢠⣮⡈⣌⠨⠅⠹⣷⡀⢱⢕
⡝⡵⠟⠈⢀⣀⣀⡀⠉⢿⣿⣿⣿⣿⣿⣿⣿⣼⣿⢈⡋⠴⢿⡟⣡⡇⣿⡇⡀⢕
⡝⠁⣠⣾⠟⡉⡉⡉⠻⣦⣻⣿⣿⣿⣿⣿⣿⣿⣿⣧⠸⣿⣦⣥⣿⡇⡿⣰⢗⢄
⠁⢰⣿⡏⣴⣌⠈⣌⠡⠈⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣬⣉⣉⣁⣄⢖⢕⢕⢕
⡀⢻⣿⡇⢙⠁⠴⢿⡟⣡⡆⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣵⣵⣿
⡻⣄⣻⣿⣌⠘⢿⣷⣥⣿⠇⣿⣿⣿⣿⣿⣿⠛⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣷⢄⠻⣿⣟⠿⠦⠍⠉⣡⣾⣿⣿⣿⣿⣿⣿⢸⣿⣦⠙⣿⣿⣿⣿⣿⣿⣿⣿⠟
⡕⡑⣑⣈⣻⢗⢟⢞⢝⣻⣿⣿⣿⣿⣿⣿⣿⠸⣿⠿⠃⣿⣿⣿⣿⣿⣿⡿⠁⣠
⡝⡵⡈⢟⢕⢕⢕⢕⣵⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣿⣿⣿⣿⣿⠿⠋⣀⣈⠙
⡝⡵⡕⡀⠑⠳⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⢉⡠⡲⡫⡪⡪⡣
                      ]]
            --       header = [[
            -- ░  ░░░░░░░░  ░░░░  ░░░      ░░░  ░░░░░░░
            -- ▒  ▒▒▒▒▒▒▒▒  ▒▒▒▒  ▒▒  ▒▒▒▒  ▒▒  ▒▒▒▒▒▒▒
            -- ▓  ▓▓▓▓▓▓▓▓        ▓▓  ▓▓▓▓▓▓▓▓       ▓▓
            -- █  ████████  ████  ██  ████  ██  ████  █
            -- █        ██  ████  ███      ███       ██
            --     ]],
                },
                sections = {
                    { section = 'header' },
                    { icon = ' ', title = 'Keymaps', section = 'keys', indent = 2, padding = 1 },
                    { icon = ' ', title = 'Recent Files', section = 'recent_files', indent = 2, padding = 1 },
                    { icon = ' ', title = 'Projects', section = 'projects', indent = 2, padding = 1 },
                    { section = 'startup' },
                },
            },
            statuscolumn = {
                folds = {
                    open = true, -- show open fold icons
                    git_hl = true, -- use Git Signs hl for fold icons
                },
            },
            image = {
                enabled = true,
                doc = {
                    enabled = true,
                    inline = false,
                    float = true,
                    max_width = 40,
                    max_height = 30,
                },
                resolve = function(_, src)
                    local vault_path = vim.fn.expand '~' .. '/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian Vault'

                    -- when the file path is *attachments/*
                    local att_path = src:match '(attachments/.*)'
                    if att_path then
                      return vault_path .. '/' .. att_path
                    end

                    -- when the file path is pure basename without any directory component
                    if not src:match '[/\\]' then
                      return vault_path .. '/attachments/' .. src
                    end

                    -- when the file path is absolute path
                    if src:match '^/' then
                      return src
                    end

                    return src
                end,
            },
            picker = {
                matcher = {
                    frecency = true,
                    cwd_bonus = true,
                    history_bonus = true,
                },
                formatters = {
                    icon_width = 3,
                },
            },
          terminal = {},
        }
    end
}

-- return {
--     'goolord/alpha-nvim',
--     lazy = false,
--     priority = 2000,
--     requires = { 'kyazdani42/nvim-web-devicons' },
--     config = function()
--         local alpha = require 'alpha'
--         local dashboard = require 'alpha.themes.dashboard'
-- 
--         math.randomseed(os.time())
-- 
--         local function footer()
--             local lazy_stats = require('lazy').stats()
--             local plugin_count = lazy_stats.count
--             local load_time = lazy_stats.startuptime
--             local datetime = os.date ' %d-%m-%Y   %H:%M:%S'
-- 
--             return string.format('⚡ %d plugins loaded in %.2fms  |  %s', plugin_count, load_time, datetime)
--         end
-- 
--         local logo = {
--             ' ⣇⣿⠘⣿⣿⣿⡿⡿⣟⣟⢟⢟⢝⠵⡝⣿⡿⢂⣼⣿⣷⣌⠩⡫⡻⣝⠹⢿⣿⣷ ',
--             ' ⡆⣿⣆⠱⣝⡵⣝⢅⠙⣿⢕⢕⢕⢕⢝⣥⢒⠅⣿⣿⣿⡿⣳⣌⠪⡪⣡⢑⢝⣇ ',
--             ' ⡆⣿⣿⣦⠹⣳⣳⣕⢅⠈⢗⢕⢕⢕⢕⢕⢈⢆⠟⠋⠉⠁⠉⠉⠁⠈⠼⢐⢕⢽ ',
--             ' ⡗⢰⣶⣶⣦⣝⢝⢕⢕⠅⡆⢕⢕⢕⢕⢕⣴⠏⣠⡶⠛⡉⡉⡛⢶⣦⡀⠐⣕⢕ ',
--             ' ⡝⡄⢻⢟⣿⣿⣷⣕⣕⣅⣿⣔⣕⣵⣵⣿⣿⢠⣿⢠⣮⡈⣌⠨⠅⠹⣷⡀⢱⢕ ',
--             ' ⡝⡵⠟⠈⢀⣀⣀⡀⠉⢿⣿⣿⣿⣿⣿⣿⣿⣼⣿⢈⡋⠴⢿⡟⣡⡇⣿⡇⡀⢕ ',
--             ' ⡝⠁⣠⣾⠟⡉⡉⡉⠻⣦⣻⣿⣿⣿⣿⣿⣿⣿⣿⣧⠸⣿⣦⣥⣿⡇⡿⣰⢗⢄ ',
--             ' ⠁⢰⣿⡏⣴⣌⠈⣌⠡⠈⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣬⣉⣉⣁⣄⢖⢕⢕⢕ ',
--             ' ⡀⢻⣿⡇⢙⠁⠴⢿⡟⣡⡆⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣵⣵⣿ ',
--             ' ⡻⣄⣻⣿⣌⠘⢿⣷⣥⣿⠇⣿⣿⣿⣿⣿⣿⠛⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿ ',
--             ' ⣷⢄⠻⣿⣟⠿⠦⠍⠉⣡⣾⣿⣿⣿⣿⣿⣿⢸⣿⣦⠙⣿⣿⣿⣿⣿⣿⣿⣿⠟ ',
--             ' ⡕⡑⣑⣈⣻⢗⢟⢞⢝⣻⣿⣿⣿⣿⣿⣿⣿⠸⣿⠿⠃⣿⣿⣿⣿⣿⣿⡿⠁⣠ ',
--             ' ⡝⡵⡈⢟⢕⢕⢕⢕⣵⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣿⣿⣿⣿⣿⠿⠋⣀⣈⠙ ',
--             ' ⡝⡵⡕⡀⠑⠳⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⢉⡠⡲⡫⡪⡪⡣ ',
--         }
-- 
--         dashboard.section.header.val = logo
-- 
--         dashboard.section.header.opts = {
--             position = "center", -- 让 logo 居中
--             hl = "Function",
--         }
-- 
--         dashboard.opts.opts = {
--             number = false,
--             relativenumber = false,
--         }
-- 
--         --
--         --    New File                  SPC n
--         --    Find File                 SPC f f
--         --  󰈙  Recents                   SPC f o
--         --  󰈭  Find Word                 SPC f w
--         --    Bookmarks                 SPC f '
--         --
-- 
--         dashboard.section.buttons.val = {
--             dashboard.button('SPC n  ', '  New File', ':ene <BAR> startinsert<CR>'),
--             dashboard.button('SPC f f', '  Find File', ':Telescope find_files<CR>'),
--             dashboard.button('SPC f o', '󰈙  Recents', ':Telescope oldfiles<CR>'),
--             dashboard.button('SPC f w', '󰈭  Find Word', ':Telescope live_grep<CR>'),
--             -- dashboard.button("SPC f '", '  Bookmarks'),
--             dashboard.button("SPC S l", '  Last Session', [[:lua require("persistence").load({ last = true })<CR>]]),
--         }
-- 
--         -- dashboard.button("ff", "  Find File", ":Telescope find_files<CR>"),
--         -- dashboard.button("fo", "󰈙  Recents", ":Telescope oldfiles<CR>"),
--         -- dashboard.button("fw", "󰈭  Find Word", ":Telescope live_grep<CR>"),
--         -- dashboard.button("Sl", "  Last Session", [[:lua require("persistence").load({ last = true })<CR>]]),
-- 
--         dashboard.section.footer.val = footer()
--         dashboard.section.footer.opts.hl = 'Type'
-- 
--         local lines = vim.o.lines
-- 
--         dashboard.config.layout = {
--             { type = 'padding', val = math.floor(lines / 4) },
--             dashboard.section.header,
--             { type = 'padding', val = 2 },
--             dashboard.section.buttons,
--             { type = 'padding', val = 1 },
--             dashboard.section.footer,
--         }
-- 
--         alpha.setup(dashboard.opts)
-- 
--         vim.cmd [[ autocmd FileType alpha setlocal nofoldenable ]]
--     end,
-- }
--


-- ---@type table<number, {token:lsp.ProgressToken, msg:string, done:boolean}[]>
-- local progress = vim.defaulttable()
-- vim.api.nvim_create_autocmd('LspProgress', {
--   ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
--   callback = function(ev)
--     local client = vim.lsp.get_client_by_id(ev.data.client_id)
--     local value = ev.data.params.value --[[@as {percentage?: number, title?: string, message?: string, kind: "begin" | "report" | "end"}]]
--     if not client or type(value) ~= 'table' then
--       return
--     end
--     local p = progress[client.id]
-- 
--     for i = 1, #p + 1 do
--       if i == #p + 1 or p[i].token == ev.data.params.token then
--         p[i] = {
--           token = ev.data.params.token,
--           msg = ('[%3d%%] %s%s'):format(
--             value.kind == 'end' and 100 or value.percentage or 100,
--             value.title or '',
--             value.message and (' **%s**'):format(value.message) or ''
--           ),
--           done = value.kind == 'end',
--         }
--         break
--       end
--     end
-- 
--     local msg = {} ---@type string[]
--     progress[client.id] = vim.tbl_filter(function(v)
--       return table.insert(msg, v.msg) or not v.done
--     end, p)
-- 
--     local spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
--     vim.notify(table.concat(msg, '\n'), 'info', {
--       id = 'lsp_progress',
--       title = client.name,
--       opts = function(notif)
--         notif.icon = #progress[client.id] == 0 and ' ' or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
--       end,
--     })
--   end,
-- })

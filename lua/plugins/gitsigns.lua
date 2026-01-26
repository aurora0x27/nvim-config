-- Git utils collection

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

---@type LazyPluginSpec
local GitUtils = {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPost', 'BufNewFile' },

    config = function()
        require('gitsigns').setup {
            signs = {
                add = { text = '┃' },
                change = { text = '┃' },
                delete = { text = '┃' },
                topdelete = { text = '┃' },
                changedelete = { text = '┃' },
                untracked = { text = '┃' },
                -- topdelete    = { text = '‾' },
                -- changedelete = { text = '~' },
                -- untracked    = { text = '┆' },
            },
            signs_staged = {
                add = { text = '┃' },
                change = { text = '┃' },
                delete = { text = '┃' },
                topdelete = { text = '┃' },
                changedelete = { text = '┃' },
                untracked = { text = '┃' },
                -- topdelete    = { text = '‾' },
                -- changedelete = { text = '~' },
                -- untracked    = { text = '┆' },
            },
            signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
            numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
            signs_staged_enable = true,
            linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
            word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
            watch_gitdir = {
                follow_files = true,
            },
            auto_attach = true,
            attach_to_untracked = false,
            current_line_blame = vim.g.enable_current_line_blame or false, -- Toggle with `:Gitsigns toggle_current_line_blame`
            current_line_blame_opts = {
                virt_text = true,
                virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
                delay = 600,
                ignore_whitespace = false,
                virt_text_priority = 100,
                use_focus = true,
            },
            current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
            sign_priority = 20,
            update_debounce = 100,
            status_formatter = nil, -- Use default
            max_file_length = 40000, -- Disable if file is longer than this (in lines)
            preview_config = {
                -- Options passed to nvim_open_win
                border = 'rounded',
                style = 'minimal',
                relative = 'cursor',
                row = 0,
                col = 1,
            },

            on_attach = function(bufnr)
                local gitsigns = require 'gitsigns'

                local function map(mode, l, r, opts)
                    opts = opts or {}
                    opts.buffer = bufnr
                    vim.keymap.set(mode, l, r, opts)
                end

                -- Navigation
                map('n', ']c', function()
                    if vim.wo.diff then
                        vim.cmd.normal { ']c', bang = true }
                    else
                        ---@diagnostic disable:param-type-mismatch
                        gitsigns.nav_hunk 'next'
                    end
                end)

                map('n', '[c', function()
                    if vim.wo.diff then
                        vim.cmd.normal { '[c', bang = true }
                    else
                        ---@diagnostic disable:param-type-mismatch
                        gitsigns.nav_hunk 'prev'
                    end
                end)

                -- Actions
                map('n', '<leader>ghs', function()
                    gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
                end, { desc = 'Git Hunk [S]tage' })

                map('n', '<leader>ghr', function()
                    gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
                end, { desc = 'Git Hunk [R]eset' })

                map('n', '<leader>ghS', gitsigns.stage_buffer, { desc = 'Git [S]tage Buffer' })
                map('n', '<leader>ghR', gitsigns.reset_buffer, { desc = 'Git [R]eset Buffer' })
                map('n', '<leader>ghp', gitsigns.preview_hunk, { desc = 'Git [P]review Hunk' })
                map('n', '<leader>ghi', gitsigns.preview_hunk_inline, { desc = 'Git Preview Hunk [I]nline' })

                map('n', '<leader>gb', function()
                    gitsigns.blame_line { full = true }
                end, { desc = 'Git [B]lame Line' })

                map('n', '<leader>gd', gitsigns.diffthis, { desc = 'Git [D]iff' })

                -- Toggles
                map('n', '<leader>gtb', gitsigns.toggle_current_line_blame, { desc = 'Git toggle current line blame' })
                map('n', '<leader>gtw', gitsigns.toggle_word_diff, { desc = 'Git toggle word diff' })

                -- Text object
                -- map({'o', 'x'}, 'ih', gitsigns.select_hunk)
            end,
        }
    end,
}

return GitUtils

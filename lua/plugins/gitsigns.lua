-- Git utils collection

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

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
            current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
            current_line_blame_opts = {
                virt_text = true,
                virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
                delay = 1000,
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
                        gitsigns.nav_hunk 'next'
                    end
                end)

                map('n', '[c', function()
                    if vim.wo.diff then
                        vim.cmd.normal { '[c', bang = true }
                    else
                        gitsigns.nav_hunk 'prev'
                    end
                end)

                -- Actions
                map('n', '<leader>ghs', gitsigns.stage_hunk, { desc = 'Git stage hunk' })
                map('n', '<leader>ghr', gitsigns.reset_hunk, { desc = 'Git reset hunk' })

                map('v', '<leader>ghs', function()
                    gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
                end, { desc = 'Git stage hunk' })

                map('v', '<leader>ghr', function()
                    gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
                end, { desc = 'Git reset hunk' })

                map('n', '<leader>ghS', gitsigns.stage_buffer, { desc = 'Git stage buffer' })
                map('n', '<leader>ghR', gitsigns.reset_buffer, { desc = 'Git reset buffer' })
                map('n', '<leader>ghp', gitsigns.preview_hunk, { desc = 'Git preview hunk' })
                map('n', '<leader>ghi', gitsigns.preview_hunk_inline, { desc = 'Git preview hunk inline' })

                map('n', '<leader>ghb', function()
                    gitsigns.blame_line { full = true }
                end, { desc = 'Git blame line' })

                map('n', '<leader>ghd', gitsigns.diffthis, { desc = 'Git diff' })

                -- map('n', '<leader>ghD', function()
                --     gitsigns.diffthis('~')
                -- end, {desc = "Git diff ~"})

                -- map('n', '<leader>ghQ', function() gitsigns.setqflist('all') end)
                -- map('n', '<leader>ghq', gitsigns.setqflist)

                -- Toggles
                map('n', '<leader>gtb', gitsigns.toggle_current_line_blame, { desc = 'Git toggle current line blame' })
                map('n', '<leader>gtd', gitsigns.toggle_deleted, { desc = 'Git toggle deleted' })
                map('n', '<leader>gtw', gitsigns.toggle_word_diff, { desc = 'Git toggle word diff' })

                -- Text object
                -- map({'o', 'x'}, 'ih', gitsigns.select_hunk)
            end,
        }
    end,
}

return GitUtils

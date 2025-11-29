-- Define some behaviors

local AutoCmd = {}

function AutoCmd.apply()
    -- Highlight yanked text
    vim.api.nvim_create_autocmd('TextYankPost', {
        pattern = '*',
        callback = function()
            vim.highlight.on_yank {
                higroup = 'IncSearch',
                timeout = 200,
            }
        end,
    })

    -- Do not display warnings
    ---@diagnostic disable: duplicate-set-field
    vim.deprecate = function() end

    vim.api.nvim_create_autocmd('BufReadPost', {
        callback = function()
            local mark = vim.api.nvim_buf_get_mark(0, '"')
            local lcount = vim.api.nvim_buf_line_count(0)
            if mark[1] > 0 and mark[1] <= lcount then
                vim.api.nvim_win_set_cursor(0, mark)
            end
        end,
        desc = 'Set cursor to the position where it was last left.',
    })

    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'help',
        callback = function()
            -- Trigger only when real `help` command is typed
            if vim.bo.buftype == 'help' then
                vim.schedule(function()
                    vim.cmd 'wincmd T'
                end)
            end
        end,
    })
end

return AutoCmd

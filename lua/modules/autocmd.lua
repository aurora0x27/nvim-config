--------------------------------------------------------------------------------
-- Define some behaviors
--------------------------------------------------------------------------------

local M = {}

function M.setup()
    local augrp = vim.api.nvim_create_augroup('Customed', { clear = false })
    -- Highlight yanked text
    vim.api.nvim_create_autocmd('TextYankPost', {
        pattern = '*',
        group = augrp,
        callback = function()
            vim.highlight.on_yank {
                higroup = 'IncSearch',
                timeout = 200,
            }
        end,
    })

    vim.api.nvim_create_autocmd('BufReadPost', {
        group = augrp,
        callback = function()
            local mark = vim.api.nvim_buf_get_mark(0, '"')
            local lcount = vim.api.nvim_buf_line_count(0)
            if mark[1] > 0 and mark[1] <= lcount then
                vim.api.nvim_win_set_cursor(0, mark)
            end
        end,
        desc = 'Set cursor to the position where it was last left.',
    })

    vim.api.nvim_create_autocmd('ModeChanged', {
        group = augrp,
        pattern = { '*:[vV\x16]*', '*:[sS\x13]*' },
        callback = function()
            vim.diagnostic.enable(false)
        end,
    })

    vim.api.nvim_create_autocmd('ModeChanged', {
        group = augrp,
        pattern = { '[vV\x16]:*', '[sS\x13]:*' },
        callback = function()
            local new_mode = vim.v.event['new_mode']
            if
                new_mode
                and not (new_mode:find('[vV\x16]') or new_mode:find('[sS\x13]'))
            then
                vim.diagnostic.enable(true)
            end
        end,
    })
end

return M

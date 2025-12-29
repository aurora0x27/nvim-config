local SessionMgr = {
    'folke/persistence.nvim',
    enabled = vim.g.session_enabled,
    dependencies = {
        'nvim-telescope/telescope.nvim',
    },
    event = 'BufReadPre', -- this will only start session saving when an actual file was opened
    init = function()
        -- load the session for the current directory
        vim.keymap.set('n', '<leader>sl', function()
            vim.schedule(function()
                local sm = require 'persistence'
                local cache = sm.current()
                if vim.fn.filereadable(cache) ~= 0 then
                    sm.load()
                else
                    vim.notify('No session in ' .. vim.fn.getcwd(), vim.log.levels.WARN)
                end
            end)
        end, { noremap = true, silent = true, desc = '[L]oad Session' })

        -- select a session to load
        vim.keymap.set('n', '<leader>ss', function()
            require('persistence').select()
        end, { noremap = true, silent = true, desc = '[S]elect Session' })

        -- -- load the last session
        -- vim.keymap.set('n', '<leader>sl', function()
        --     require('persistence').load { last = true }
        -- end, { noremap = true, silent = true, desc = '[L]oad Last Session' })

        -- stop Persistence => session won't be saved on exit
        vim.keymap.set('n', '<leader>sd', function()
            require('persistence').stop()
        end, { noremap = true, silent = true, desc = "[D]on't Save On Exit" })

        -- save folds and view (cursor position, etc.)
        vim.api.nvim_create_autocmd('BufWinLeave', {
            pattern = '*',
            callback = function()
                if vim.bo.buftype == '' then
                    ---@diagnostic disable:param-type-mismatch
                    pcall(vim.cmd, 'mkview')
                end
            end,
        })

        -- restore view on reenter buffer
        vim.api.nvim_create_autocmd('BufWinEnter', {
            pattern = '*',
            callback = function()
                if vim.bo.buftype == '' then
                    ---@diagnostic disable:param-type-mismatch
                    pcall(vim.cmd, 'silent! loadview')
                end
            end,
        })
    end,
    opts = {
        dir = vim.fn.stdpath 'state' .. '/sessions/',
        need = 1,
    },
}

return SessionMgr

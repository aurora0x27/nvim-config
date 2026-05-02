--------------------------------------------------------------------------------
-- Session manager
--------------------------------------------------------------------------------

local sandbox = require 'core.sandbox'.get_mask()

---@type LazyPluginSpec
local SessionMgr = {
    'folke/persistence.nvim',
    enabled = sandbox.session,
    dependencies = {
        'ibhagwan/fzf-lua',
    },
    event = 'BufReadPre', -- this will only start session saving when an actual file was opened
    ---@module 'persistence'
    opts = {
        dir = vim.fn.stdpath 'state' .. '/sessions/',
        need = 1,
    },
    config = function(_, opts)
        require('persistence').setup(opts)
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
}

return SessionMgr

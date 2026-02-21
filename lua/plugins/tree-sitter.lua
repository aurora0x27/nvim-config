-- Regex highlighter

-- if true then return {} end   -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local TSEnsureInstalled = require('modules.lang').get_ts_install_list()

---@type LazyPluginSpec
local TreeSitter = {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    event = { 'VeryLazy' },
    opts = {
        install_dir = vim.fn.stdpath 'data' .. '/site',
    },
    init = function()
        vim.api.nvim_create_autocmd({ 'FileType' }, {
            pattern = TSEnsureInstalled,
            callback = function()
                vim.treesitter.start()
            end,
        })
    end,
    config = function(_, opts)
        local TS = require 'nvim-treesitter'
        TS.setup(opts)
        TS.install(TSEnsureInstalled)
    end,
}

return TreeSitter

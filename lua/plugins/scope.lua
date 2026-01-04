---@type LazyPluginSpec
local ScopeMgr = {
    'tiagovla/scope.nvim',
    event = { 'BufReadPost', 'BufNewFile', 'BufReadPre' },
    config = function()
        vim.opt.sessionoptions = {
            'buffers',
            'tabpages',
            'globals',
        }
        require('scope').setup {
            hooks = {},
        }
    end,
}

return ScopeMgr

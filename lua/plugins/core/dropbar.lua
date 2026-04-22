--------------------------------------------------------------------------------
-- Dropbar, annotions the scope for current cursor pos context
--------------------------------------------------------------------------------

local thunk = require 'utils.loader'.thunk

---@type LazyPluginSpec
local Outline = {
    'Bekaboo/dropbar.nvim',
    enabled = Profile.enable_dropbar,
    event = { 'BufReadPost', 'BufNewFile' },
    ---@module 'dropbar'
    keys = {
        {
            '<leader>;s',
            thunk('dropbar.api', 'pick'),
            mode = { 'n' },
            desc = '[S]ymbols In Dropbar',
        },
    },
}

return Outline

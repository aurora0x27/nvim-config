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
    ---@type dropbar_configs_t
    opts = {
        bar = {
            update_events = {
                buf = { 'FileChangedShellPost', 'TextChanged', 'ModeChanged' },
            },
        },
    },
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

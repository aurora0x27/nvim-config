--------------------------------------------------------------------------------
-- Dropbar, annotions the scope for current cursor pos context
--------------------------------------------------------------------------------

local thunk = require 'utils.loader'.thunk

---@type LazyPluginSpec
local Outline = {
    'Bekaboo/dropbar.nvim',
    -- optional, but required for fuzzy finder support
    event = { 'BufReadPost', 'BufNewFile' },
    ---@module 'dropbar'
    ---@type dropbar_opts_t
    opts = {},
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

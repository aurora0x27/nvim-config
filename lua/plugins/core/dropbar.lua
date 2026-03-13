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
            '<leader>;',
            thunk('dropbar.api', 'pick'),
            mode = { 'n' },
            desc = 'Pick Symbols In Dropbar',
        },
    },
}

return Outline

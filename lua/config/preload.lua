-- This file contains settings load before initializing lazy
local Preload = {}

function Preload.apply()
    -- set global leader
    vim.g.mapleader = ' '
    vim.g.maplocalleader = ' '

    -- sets vim.opt.number
    -- WARN: put this line here instead of `options.lua`
    -- prevents line number appear on dashboard, werid.
    vim.opt.number = true
end

return Preload

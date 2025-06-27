-- This file contains settings load before initializing lazy
local preload = {}

function preload.apply()
    vim.opt.number = true -- sets vim.opt.number
end

return preload

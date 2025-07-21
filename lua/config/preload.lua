-- This file contains settings load before initializing lazy
local Preload = {}

function Preload.apply()
    vim.opt.number = true -- sets vim.opt.number
end

return Preload

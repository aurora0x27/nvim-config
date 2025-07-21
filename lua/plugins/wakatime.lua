-- Wakatime for fun

-- if true then return {} end   -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local WakaTime = {
    'wakatime/vim-wakatime',
    -- lazy = false ,
    event = { 'BufReadPost', 'BufNewFile' },
}

return WakaTime

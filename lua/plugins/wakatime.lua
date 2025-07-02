-- if true then return {} end   -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
    'wakatime/vim-wakatime',
    -- lazy = false ,
    event = { 'BufReadPost', 'BufNewFile' },
}

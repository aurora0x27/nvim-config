-- IME auto switcher
-- FIXME: only work on linux

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local ImeSwitcher = { 'www9song/fcitx5-nvim-zh', event = { 'BufReadPost', 'BufNewFile' } }

return ImeSwitcher

-- This file contains keymaps, which is executed after lazy initialization
local keymaps = {};

keymaps.opt = {}

function keymaps.apply()
    -- buffer swich
    vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
    vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to below window" })
    vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to above window" })
    vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })
end

return keymaps

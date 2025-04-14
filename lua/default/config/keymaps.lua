-- This file contains keymaps, which is executed after lazy initialization
local keymaps = {};

keymaps.opt = {}

function keymaps.apply()
    -- resize window
    vim.keymap.set("n", "<C-Left>", "<C-w>>", {noremap = true, silent = true})
    vim.keymap.set("n", "<C-Right>", "<C-w><", {noremap = true, silent = true})

    -- buffer swich
    vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
    vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to below window" })
    vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to above window" })
    vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })
    vim.keymap.set("n", "H", ":bp<Enter>", {noremap = true, silent = true})
    vim.keymap.set("n", "L", ":bn<Enter>", {noremap = true, silent = true})

    -- telescope related, prefix is leader-t
    vim.keymap.set("n", "<Leader>ff", ":Telescope find_files<Enter>", { desc = "Telescope Find Files" })
    vim.keymap.set("n", "<Leader>fo", ":Telescope oldfiles<Enter>", { desc = "Telescope Find Recent Files" })
    vim.keymap.set("n", "<Leader>fw", ":Telescope live_grep<Enter>", { desc = "Telescope Find Word" })
    vim.keymap.set("n", "<Leader>fb", ":Telescope buffers<Enter>", { desc = "Telescope Find Buffer" })

    -- buffer releated, prefix is leader-b
    vim.keymap.set("n", "<Leader>bc", ":bdelete<Enter>", { desc = "Buffer close current" })
end

return keymaps

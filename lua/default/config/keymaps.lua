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
    vim.keymap.set("n", "<Leader>ff", ":Telescope find_files<Enter>", { desc = "Telescope Find Files", noremap = true, silent = true})
    vim.keymap.set("n", "<Leader>fo", ":Telescope oldfiles<Enter>", { desc = "Telescope Find Recent Files", noremap = true, silent = true})
    vim.keymap.set("n", "<Leader>fw", ":Telescope live_grep<Enter>", { desc = "Telescope Find Word", noremap = true, silent = true})
    vim.keymap.set("n", "<Leader>fb", ":Telescope buffers<Enter>", { desc = "Telescope Find Buffer", noremap = true, silent = true})
    vim.keymap.set("n", "<Leader>fd", ":Telescope diagnostics<Enter>", { desc = "Telescope Find Diagnostics", noremap = true, silent = true})

    -- buffer releated, prefix is leader-b
    vim.keymap.set("n", "<Leader>bc", ":bdelete<Enter>", { desc = "Buffer close current", noremap = true, silent = true })
    vim.keymap.set("n", "<Leader>bl", ":Telescope buffers<Enter>", { desc = "Buffer list", noremap = true, silent = true })

    vim.keymap.set("n", "<Leader>h", ":Alpha<Enter>", {desc = "Open Home Page", noremap = true, silent = true })
end

return keymaps

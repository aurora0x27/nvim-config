-- File system explorer

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
        "MunifTanjim/nui.nvim",
        -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
    },
    config = function()
        require("neo-tree").setup({
            close_if_last_window = true,
            filesystem = {
                follow_current_file = {enabled = true},
                hijack_netrw = true,
            },
        })

        vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle NeoTree file explorer" })
    end,
}

-- return {
--     "mikavilpas/yazi.nvim",
--     event = "VeryLazy",
--     dependencies = {
--         -- check the installation instructions at
--         -- https://github.com/folke/snacks.nvim
--         -- "folke/snacks.nvim"
--     },
--     keys = {
--         -- 👇 in this section, choose your own keymappings!
--         -- {
--         --     "<leader>-",
--         --     mode = { "n", "e" },
--         --     "<cmd>Yazi<cr>",
--         --     desc = "Open yazi at the current file",
--         -- },
--         {
--             -- Open in the current working directory
--             "<leader>e",
--             "<cmd>Yazi cwd<cr>",
--             desc = "Open the file manager in nvim's working directory",
--         },
--         {
--             "<c-up>",
--             "<cmd>Yazi toggle<cr>",
--             desc = "Resume the last yazi session",
--         },
--     },
--     ---@type YaziConfig | {}
--     opts = {
--         -- if you want to open yazi instead of netrw, see below for more info
--         open_for_directories = false,
--         keymaps = {
--             show_help = "<f1>",
--         },
--     },
--     -- 👇 if you use `open_for_directories=true`, this is recommended
--     init = function()
--         -- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
--         -- vim.g.loaded_netrw = 1
--         vim.g.loaded_netrwPlugin = 1
--     end,
-- }

-- This file contains keymaps, which is executed after lazy initialization

local KeyMaps = {}

function KeyMaps.apply()
    -- resize window
    local smsp = require 'smart-splits'
    vim.keymap.set('n', '<C-Left>', smsp.resize_left, { noremap = true, silent = true })
    vim.keymap.set('n', '<C-Right>', smsp.resize_right, { noremap = true, silent = true })
    vim.keymap.set('n', '<C-Up>', smsp.resize_up, { noremap = true, silent = true })
    vim.keymap.set('n', '<C-Down>', smsp.resize_down, { noremap = true, silent = true })

    -- buffer swich
    vim.keymap.set('n', '<C-h>', smsp.move_cursor_left, { desc = 'Move to left window', noremap = true, silent = true })
    vim.keymap.set(
        'n',
        '<C-j>',
        smsp.move_cursor_down,
        { desc = 'Move to below window', noremap = true, silent = true }
    )
    vim.keymap.set('n', '<C-k>', smsp.move_cursor_up, { desc = 'Move to above window', noremap = true, silent = true })
    vim.keymap.set(
        'n',
        '<C-l>',
        smsp.move_cursor_right,
        { desc = 'Move to right window', noremap = true, silent = true }
    )

    vim.keymap.set('n', 'H', '<cmd>bp<CR>', { noremap = true, silent = true })
    vim.keymap.set('n', 'L', '<cmd>bn<CR>', { noremap = true, silent = true })

    -- telescope related, prefix is leader-t
    local builtin = require 'telescope.builtin'
    vim.keymap.set(
        'n',
        '<Leader>ff',
        builtin.find_files,
        { desc = 'Telescope Find Files', noremap = true, silent = true }
    )
    vim.keymap.set(
        'n',
        '<Leader>fo',
        builtin.oldfiles,
        { desc = 'Telescope Find Recent Files', noremap = true, silent = true }
    )
    vim.keymap.set(
        'n',
        '<Leader>fw',
        builtin.live_grep,
        { desc = 'Telescope Find Word', noremap = true, silent = true }
    )
    vim.keymap.set(
        'n',
        '<Leader>fb',
        builtin.buffers,
        { desc = 'Telescope Find Buffer', noremap = true, silent = true }
    )
    vim.keymap.set(
        'n',
        '<Leader>fd',
        builtin.diagnostics,
        { desc = 'Telescope Find Diagnostics', noremap = true, silent = true }
    )
    vim.keymap.set(
        'n',
        '<Leader>fg',
        builtin.git_status,
        { desc = 'Telescope Find Git Diff', noremap = true, silent = true }
    )
    vim.keymap.set(
        'n',
        '<Leader>fs',
        builtin.lsp_dynamic_workspace_symbols,
        { desc = 'Telescope Find Workspace Symbols', noremap = true, silent = true }
    )
    vim.keymap.set(
        'n',
        '<Leader>fm',
        require('telescope').extensions.noice.noice,
        { desc = 'Telescope Filter Noice Msg', noremap = true, silent = true }
    )
    vim.keymap.set(
        'n',
        '<Leader>ft',
        '<cmd>TodoTelescope<CR>',
        { desc = 'Telescope Filter Todo Items', noremap = true, silent = true }
    )

    -- buffer releated, prefix is leader-b
    vim.keymap.set(
        'n',
        '<Leader>bc',
        ':bp | bd #<Enter>',
        { desc = 'Buffer close current', noremap = true, silent = true }
    )

    vim.keymap.set('n', '<Leader>h', '<cmd>Alpha<CR>', { desc = 'Open Home Page', noremap = true, silent = true })
    vim.keymap.set(
        'n',
        '<Leader>lg',
        builtin.git_commits,
        { desc = 'Search Git Commits', noremap = true, silent = true }
    )
    vim.keymap.set(
        'n',
        '<Leader>lD',
        builtin.diagnostics,
        { desc = 'Search diagnostics', noremap = true, silent = true }
    )

    vim.keymap.set({ 'n', 'v' }, 'j', 'gj', { noremap = true, silent = true })
    vim.keymap.set({ 'n', 'v' }, 'k', 'gk', { noremap = true, silent = true })

    -- File explorer
    vim.keymap.set('n', '<leader>e', '<cmd>Neotree toggle<CR>', {
        desc = 'Toggle NeoTree file explorer',
        noremap = true,
        silent = true,
    })

    -- Clean search highlight
    vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { silent = true })
end

return KeyMaps

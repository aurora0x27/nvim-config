-- This file contains keymaps, which is executed after lazy initialization

local KeyMaps = {}

function KeyMaps.apply()
    local function select(module, ...)
        local fields = { ... }
        return function()
            local mod = require(module)
            for i = 1, #fields - 1 do
                mod = mod[fields[i]]
            end
            mod[fields[#fields]]()
        end
    end

    -- resize window
    vim.keymap.set('n', '<C-Left>', select('smart-splits', 'resize_left'), { noremap = true, silent = true })
    vim.keymap.set('n', '<C-Right>', select('smart-splits', 'resize_right'), { noremap = true, silent = true })
    vim.keymap.set('n', '<C-Up>', select('smart-splits', 'resize_up'), { noremap = true, silent = true })
    vim.keymap.set('n', '<C-Down>', select('smart-splits', 'resize_down'), { noremap = true, silent = true })

    -- buffer swich
    vim.keymap.set(
        'n',
        '<C-h>',
        select('smart-splits', 'move_cursor_left'),
        { desc = 'Move to left window', noremap = true, silent = true }
    )
    vim.keymap.set(
        'n',
        '<C-j>',
        select('smart-splits', 'move_cursor_down'),
        { desc = 'Move to below window', noremap = true, silent = true }
    )
    vim.keymap.set(
        'n',
        '<C-k>',
        select('smart-splits', 'move_cursor_up'),
        { desc = 'Move to above window', noremap = true, silent = true }
    )
    vim.keymap.set(
        'n',
        '<C-l>',
        select('smart-splits', 'move_cursor_right'),
        { desc = 'Move to right window', noremap = true, silent = true }
    )

    vim.keymap.set('n', 'H', '<cmd>bp<CR>', { noremap = true, silent = true })
    vim.keymap.set('n', 'L', '<cmd>bn<CR>', { noremap = true, silent = true })

    -- telescope related, prefix is leader-t
    vim.keymap.set(
        'n',
        '<Leader>ff',
        select('telescope.builtin', 'find_files'),
        { desc = 'Telescope Find Files', noremap = true, silent = true }
    )
    vim.keymap.set(
        'n',
        '<Leader>fo',
        select('telescope.builtin', 'oldfiles'),
        { desc = 'Telescope Find Recent Files', noremap = true, silent = true }
    )
    vim.keymap.set(
        'n',
        '<Leader>fw',
        select('telescope.builtin', 'live_grep'),
        { desc = 'Telescope Find Word', noremap = true, silent = true }
    )
    vim.keymap.set(
        'n',
        '<Leader>fb',
        select('telescope.builtin', 'buffers'),
        { desc = 'Telescope Find Buffer', noremap = true, silent = true }
    )
    vim.keymap.set(
        'n',
        '<Leader>fd',
        select('telescope.builtin', 'diagnostics'),
        { desc = 'Telescope Find Diagnostics', noremap = true, silent = true }
    )
    vim.keymap.set(
        'n',
        '<Leader>fg',
        select('telescope.builtin', 'git_status'),
        { desc = 'Telescope Find Git Diff', noremap = true, silent = true }
    )
    vim.keymap.set(
        'n',
        '<Leader>fs',
        select('telescope.builtin', 'lsp_dynamic_workspace_symbols'),
        { desc = 'Telescope Find Workspace Symbols', noremap = true, silent = true }
    )
    vim.keymap.set(
        'n',
        '<Leader>fm',
        select('telescope', 'extensions', 'noice', 'noice'),
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
        '<cmd>bp | bd #<CR>',
        { desc = 'Buffer close current', noremap = true, silent = true }
    )
    vim.keymap.set(
        'n',
        '<Leader>lg',
        select('telescope.builtin', 'git_commits'),
        { desc = 'Search Git Commits', noremap = true, silent = true }
    )
    vim.keymap.set(
        'n',
        '<Leader>lD',
        select('telescope.builtin', 'diagnostics'),
        { desc = 'Search diagnostics', noremap = true, silent = true }
    )

    vim.keymap.set({ 'n', 'v' }, 'j', 'gj', { noremap = true, silent = true })
    vim.keymap.set({ 'n', 'v' }, 'k', 'gk', { noremap = true, silent = true })

    vim.keymap.set('n', '<Leader>h', '<cmd>Alpha<CR>', { desc = 'Open Home Page', noremap = true, silent = true })

    -- File explorer
    vim.keymap.set('n', '<leader>e', '<cmd>Neotree toggle<CR>', {
        desc = 'Toggle NeoTree file explorer',
        noremap = true,
        silent = true,
    })

    -- Clean search highlight
    vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { silent = true })

    -- Delete j and k in select mode
    vim.keymap.del('s', 'j')
    vim.keymap.del('s', 'k')

    vim.keymap.set('n', '-', '<cmd>Oil<CR>', { desc = 'Open parent directory' })


    -- Not frequently used
    -- vim.keymap.set('i', '<C-j>', '<Down>', { noremap = true, silent = true })
    -- vim.keymap.set('i', '<C-k>', '<Up>', { noremap = true, silent = true })
    vim.keymap.set('i', '<C-h>', '<Left>', { noremap = true, silent = true })
    vim.keymap.set('i', '<C-l>', '<Right>', { noremap = true, silent = true })
end

return KeyMaps

-- This file contains keymaps, which is executed after lazy initialization

local KeyMaps = {}

local log = require 'utils.tools'

function KeyMaps.apply()
    local select = require('utils.loader').select
    local bind = require('utils.loader').bind

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
        { desc = 'Telescope Find [F]iles', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fo',
        select('telescope.builtin', 'oldfiles'),
        { desc = 'Telescope Find [O]ld Files', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>ft',
        select('telescope.builtin', 'treesitter'),
        { desc = 'Telescope Find [T]reesitter Symbols', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fw',
        select('telescope.builtin', 'live_grep'),
        { desc = 'Telescope [W]ildcard Grep', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fb',
        select('telescope.builtin', 'buffers'),
        { desc = 'Telescope Find [B]uffer', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fd',
        select('telescope.builtin', 'diagnostics'),
        { desc = 'Telescope Find [D]iagnostics', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fC',
        select('telescope.builtin', 'highlights'),
        { desc = 'Telescope Find Highlight [C]olors', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fgs',
        select('telescope.builtin', 'git_status'),
        { desc = 'Telescope Find [G]it [S]tatus', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fgc',
        select('telescope.builtin', 'git_commits'),
        { desc = 'Telescope Find [G]it [C]ommits', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fgbc',
        select('telescope.builtin', 'git_bcommits'),
        { desc = 'Telescope Find [G]it [B]uffer [C]ommits', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fgbr',
        select('telescope.builtin', 'git_branches'),
        { desc = 'Telescope Find [G]it [BR]anches', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fm',
        select('telescope', 'extensions', 'noice', 'noice'),
        { desc = 'Telescope Find Noice [M]sg', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fT',
        '<cmd>TodoTelescope<CR>',
        { desc = 'Telescope Find [T]odo Items', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>f:',
        select('telescope.builtin', 'command_history'),
        { desc = 'Telescope Find Command History', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fR',
        select('telescope.builtin', 'registers'),
        { desc = 'Telescope Find [R]egister', noremap = true, silent = true }
    )

    -- buffer releated, prefix is leader-b
    vim.keymap.set(
        'n',
        '<Leader>bc',
        '<cmd>bp | bd #<CR>',
        { desc = 'Buffer [C]lose Current', noremap = true, silent = true }
    )

    vim.keymap.set({ 'n', 'v' }, 'j', 'gj', { noremap = true, silent = true })
    vim.keymap.set({ 'n', 'v' }, 'k', 'gk', { noremap = true, silent = true })

    vim.keymap.set('n', '<Leader>h', '<cmd>Alpha<CR>', { desc = 'Open [H]ome Page', noremap = true, silent = true })

    -- File explorer
    vim.keymap.set('n', '<leader>e', '<cmd>Neotree toggle<CR>', {
        desc = 'Toggle File [E]xplorer',
        noremap = true,
        silent = true,
    })

    -- Clean search highlight
    vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { silent = true })

    -- Delete j and k in select mode
    vim.keymap.del('s', 'j')
    vim.keymap.del('s', 'k')

    vim.keymap.set(
        'n',
        '-',
        bind(select('oil', 'open_float'), nil, { preview = { horizontal = true } }),
        { desc = 'Open parent directory' }
    )

    -- Not frequently used
    -- vim.keymap.set('i', '<C-j>', '<Down>', { noremap = true, silent = true })
    -- vim.keymap.set('i', '<C-k>', '<Up>', { noremap = true, silent = true })
    vim.keymap.set('i', '<C-h>', '<Left>', { noremap = true, silent = true })
    vim.keymap.set('i', '<C-l>', '<Right>', { noremap = true, silent = true })

    -- Use ctrl-/ to goto normal mode, so weird
    if vim.env.TMUX then
        vim.keymap.set('t', '<C-_>', '<cmd>stopinsert<cr>', { noremap = true, silent = true })
    else
        vim.keymap.set('t', '<C-/>', '<cmd>stopinsert<cr>', { noremap = true, silent = true })
    end

    vim.keymap.set(
        { 'n' },
        '<Leader>tt',
        '<cmd>tabnext<cr>',
        { noremap = true, silent = true, desc = '[T]ab switch next' }
    )
    vim.keymap.set({ 'n' }, '<Leader>tn', function()
        local name = vim.fn.input('File name: ', '', 'file')
        if name ~= '' then
            vim.cmd('tabnew ' .. name)
        else
            log.warn 'Warn: Filename not assigned, nothing todo'
        end
    end, { noremap = true, silent = true, desc = 'Tab [N]ew' })
    vim.keymap.set(
        { 'n' },
        '<Leader>tp',
        '<cmd>tabprevious<cr>',
        { noremap = true, silent = true, desc = 'Tab [P]revious' }
    )
    vim.keymap.set(
        { 'n' },
        '<Leader>ta',
        '<cmd>tabnew %<cr>',
        { noremap = true, silent = true, desc = 'Tab [A]dd With Current Buffer' }
    )
    vim.keymap.set({ 'n' }, '<Leader>tc', '<cmd>tabclose<cr>', { noremap = true, silent = true, desc = 'Tab [C]lose' })

    vim.keymap.set(
        { 'n' },
        '<Leader>lm',
        select('mason.ui', 'open'),
        { noremap = true, silent = true, desc = 'Launch Lsp [M]anager' }
    )

    if not vim.g.session_enabled then
        vim.keymap.set('n', '<leader>sl', function()
            local oldfiles = vim.v.oldfiles
            for _, file in ipairs(oldfiles) do
                if vim.fn.filereadable(file) == 1 then
                    vim.cmd('edit ' .. vim.fn.fnameescape(file))
                    return
                end
            end
            log.warn 'No previous file found in v:oldfiles'
        end, { noremap = true, silent = true, desc = 'Recover [L]ast Buffer' })
    end

    local mvblk = require 'utils.mvblk'
    vim.keymap.set('v', '<c-j>', function()
        mvblk 'down'
    end, { noremap = true, silent = true, desc = 'Move Selected Line Downward' })
    vim.keymap.set('v', '<c-k>', function()
        mvblk 'up'
    end, { noremap = true, silent = true, desc = 'Move Selected Line Upward' })
end

return KeyMaps

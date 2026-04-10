--------------------------------------------------------------------------------
-- This file contains keymaps, which is executed after lazy initialization
--------------------------------------------------------------------------------

local M = {}

local thunk = require('utils.loader').thunk
local bind = require('utils.loader').bind
local map = vim.keymap.set

function M.setup()
    require 'modules.keymaps.buffer'
    require 'modules.keymaps.window'
    require 'modules.keymaps.tab'
    require 'modules.keymaps.finder'
    require 'modules.keymaps.sandbox'

    ----------------------------------------------------------------------------
    -- insert mode move cursor
    ----------------------------------------------------------------------------
    map('i', '<C-j>', '<Down>', { noremap = true, silent = true })
    map('i', '<C-k>', '<Up>', { noremap = true, silent = true })
    map('i', '<C-h>', '<Left>', { noremap = true, silent = true })
    map('i', '<C-l>', '<Right>', { noremap = true, silent = true })

    ----------------------------------------------------------------------------
    -- Use ctrl-/ to goto normal mode, so weird
    ----------------------------------------------------------------------------
    if vim.env.TMUX then
        map(
            't',
            '<C-_>',
            '<cmd>stopinsert<cr>',
            { noremap = true, silent = true }
        )
    else
        map(
            't',
            '<C-/>',
            '<cmd>stopinsert<cr>',
            { noremap = true, silent = true }
        )
    end

    ----------------------------------------------------------------------------
    -- Move block
    ----------------------------------------------------------------------------
    map(
        'v',
        '<c-j>',
        bind(require 'utils.mvblk', 'down'),
        { noremap = true, silent = true, desc = 'Move Selected Line Downward' }
    )
    map(
        'v',
        '<c-k>',
        bind(require 'utils.mvblk', 'up'),
        { noremap = true, silent = true, desc = 'Move Selected Line Upward' }
    )

    ----------------------------------------------------------------------------
    -- Clean search highlight and snippet highlight
    ----------------------------------------------------------------------------
    map('n', '<Esc>', function()
        vim.cmd 'nohlsearch'
        if vim.snippet then
            vim.snippet.stop()
        end
    end, { silent = true })

    ----------------------------------------------------------------------------
    -- File explorer
    ----------------------------------------------------------------------------
    map('n', '<leader>e', function()
        local open = require 'mini.files'.open
        local close = require 'mini.files'.close
        if not close() then
            open()
        end
    end, {
        desc = 'Toggle File [E]xplorer',
        noremap = true,
        silent = true,
    })
    map(
        'n',
        '-',
        bind(
            thunk('oil', 'open_float'),
            nil,
            { preview = { horizontal = true } }
        ),
        { desc = 'Open parent directory' }
    )

    map({ 'n', 'v' }, 'j', 'gj', { noremap = true, silent = true })
    map({ 'n', 'v' }, 'k', 'gk', { noremap = true, silent = true })

    -- Delete j and k under select mode to enable snippet
    vim.keymap.del('s', 'j')
    vim.keymap.del('s', 'k')

    map(
        'n',
        '<leader>h',
        '<cmd>Alpha<CR>',
        { desc = 'Open [H]ome Page', noremap = true, silent = true }
    )
    map(
        { 'n' },
        '<leader>lm',
        thunk('mason.ui', 'open'),
        { noremap = true, silent = true, desc = 'Launch Lsp [M]anager' }
    )
end

return M

-- This file contains keymaps, which is executed after lazy initialization

local M = {}

local log = require 'utils.tools'

function M.setup()
    local thunk = require('utils.loader').thunk
    local bind = require('utils.loader').bind

    -- resize window
    vim.keymap.set('n', '<C-Left>', thunk('smart-splits', 'resize_left'), { noremap = true, silent = true })
    vim.keymap.set('n', '<C-Right>', thunk('smart-splits', 'resize_right'), { noremap = true, silent = true })
    vim.keymap.set('n', '<C-Up>', thunk('smart-splits', 'resize_up'), { noremap = true, silent = true })
    vim.keymap.set('n', '<C-Down>', thunk('smart-splits', 'resize_down'), { noremap = true, silent = true })

    -- buffer swich
    vim.keymap.set(
        'n',
        '<C-h>',
        thunk('smart-splits', 'move_cursor_left'),
        { desc = 'Move to left window', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<C-j>',
        thunk('smart-splits', 'move_cursor_down'),
        { desc = 'Move to below window', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<C-k>',
        thunk('smart-splits', 'move_cursor_up'),
        { desc = 'Move to above window', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<C-l>',
        thunk('smart-splits', 'move_cursor_right'),
        { desc = 'Move to right window', noremap = true, silent = true }
    )

    vim.keymap.set('n', 'H', '<cmd>bp<CR>', { noremap = true, silent = true })
    vim.keymap.set('n', 'L', '<cmd>bn<CR>', { noremap = true, silent = true })

    -- Fzflua related, prefix is leader-t
    vim.keymap.set(
        'n',
        '<Leader>ff',
        thunk('fzf-lua', 'files'),
        { desc = 'Fzflua Find [F]iles', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fo',
        thunk('fzf-lua', 'oldfiles'),
        { desc = 'Fzflua Find [O]ld Files', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>ft',
        thunk('fzf-lua', 'treesitter'),
        { desc = 'Fzflua Find [T]reesitter Symbols', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fw',
        thunk('fzf-lua', 'live_grep'),
        { desc = 'Fzflua [W]ildcard Grep', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fb',
        thunk('fzf-lua', 'buffers'),
        { desc = 'Fzflua Find [B]uffer', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fB',
        thunk('fzf-lua', 'builtin'),
        { desc = 'Fzflua Find [B]uiltin', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fd',
        thunk('fzf-lua', 'diagnostics_document'),
        { desc = 'Fzflua Find Document [D]iagnostics', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fD',
        thunk('fzf-lua', 'diagnostics_workspace'),
        { desc = 'Fzflua Find Workspace [D]iagnostics', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fC',
        thunk('fzf-lua', 'highlights'),
        { desc = 'Fzflua Find Highlight [C]olors', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fgs',
        thunk('fzf-lua', 'git_status'),
        { desc = 'Fzflua Find [G]it [S]tatus', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fgc',
        thunk('fzf-lua', 'git_commits'),
        { desc = 'Fzflua Find [G]it [C]ommits', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fgbc',
        thunk('fzf-lua', 'git_bcommits'),
        { desc = 'Fzflua Find [G]it [B]uffer [C]ommits', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fgbr',
        thunk('fzf-lua', 'git_branches'),
        { desc = 'Fzflua Find [G]it [BR]anches', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fm',
        thunk('noice.integrations.fzf', 'open'),
        { desc = 'Fzflua Find Noice [M]sg', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fT',
        '<cmd>TodoFzfLua<CR>',
        { desc = 'FzfLua Find [T]odo Items', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>f:',
        thunk('fzf-lua', 'command_history'),
        { desc = 'Fzflua Find Command History', noremap = true, silent = true }
    )

    vim.keymap.set(
        'n',
        '<Leader>fR',
        thunk('fzf-lua', 'registers'),
        { desc = 'Fzflua Find [R]egister', noremap = true, silent = true }
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
    vim.keymap.set(
        'n',
        '<leader>e',
        bind(thunk('neo-tree.command', 'execute'), { action = 'show', source = 'filesystem', toggle = true }),
        {
            desc = 'Toggle File [E]xplorer',
            noremap = true,
            silent = true,
        }
    )

    vim.keymap.set(
        'n',
        '<leader>o',
        bind(thunk('neo-tree.command', 'execute'), { action = 'show', source = 'document_symbols', toggle = true }),
        {
            desc = 'Toggle [O]utline',
            noremap = true,
            silent = true,
        }
    )

    -- Clean search highlight
    vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { silent = true })

    -- Delete j and k in select mode
    vim.keymap.del('s', 'j')
    vim.keymap.del('s', 'k')

    vim.keymap.set(
        'n',
        '-',
        bind(thunk('oil', 'open_float'), nil, { preview = { horizontal = true } }),
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
        thunk('mason.ui', 'open'),
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

    vim.keymap.set(
        'v',
        '<c-j>',
        bind(thunk('utils', 'mvblk'), 'down'),
        { noremap = true, silent = true, desc = 'Move Selected Line Downward' }
    )

    vim.keymap.set(
        'v',
        '<c-k>',
        bind(thunk('utils', 'mvblk'), 'up'),
        { noremap = true, silent = true, desc = 'Move Selected Line Upward' }
    )
end

return M

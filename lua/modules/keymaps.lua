-- This file contains keymaps, which is executed after lazy initialization

local M = {}

local misc = require 'utils.misc'
local thunk = require('utils.loader').thunk
local bind = require('utils.loader').bind
local map = vim.keymap.set

function M.setup()
    -- resize window
    map(
        'n',
        '<C-Left>',
        thunk('smart-splits', 'resize_left'),
        { noremap = true, silent = true }
    )
    map(
        'n',
        '<C-Right>',
        thunk('smart-splits', 'resize_right'),
        { noremap = true, silent = true }
    )
    map(
        'n',
        '<C-Up>',
        thunk('smart-splits', 'resize_up'),
        { noremap = true, silent = true }
    )
    map(
        'n',
        '<C-Down>',
        thunk('smart-splits', 'resize_down'),
        { noremap = true, silent = true }
    )

    -- buffer swich
    map(
        'n',
        '<C-h>',
        thunk('smart-splits', 'move_cursor_left'),
        { desc = 'Move to left window', noremap = true, silent = true }
    )

    map(
        'n',
        '<C-j>',
        thunk('smart-splits', 'move_cursor_down'),
        { desc = 'Move to below window', noremap = true, silent = true }
    )

    map(
        'n',
        '<C-k>',
        thunk('smart-splits', 'move_cursor_up'),
        { desc = 'Move to above window', noremap = true, silent = true }
    )

    map(
        'n',
        '<C-l>',
        thunk('smart-splits', 'move_cursor_right'),
        { desc = 'Move to right window', noremap = true, silent = true }
    )

    map('n', 'H', '<cmd>bp<CR>', { noremap = true, silent = true })
    map('n', 'L', '<cmd>bn<CR>', { noremap = true, silent = true })

    -- Fzflua related, prefix is leader-t
    map(
        'n',
        '<Leader>ff',
        thunk('fzf-lua', 'files'),
        { desc = 'Find [F]iles', noremap = true, silent = true }
    )

    map(
        'n',
        '<Leader>fo',
        thunk('fzf-lua', 'oldfiles'),
        { desc = 'Find [O]ld Files', noremap = true, silent = true }
    )

    map(
        'n',
        '<Leader>ft',
        thunk('fzf-lua', 'treesitter'),
        { desc = 'Find [T]reesitter Symbols', noremap = true, silent = true }
    )

    map(
        'n',
        '<Leader>fw',
        thunk('fzf-lua', 'live_grep'),
        { desc = '[W]ildcard Grep', noremap = true, silent = true }
    )

    map(
        'n',
        '<Leader>fb',
        thunk('fzf-lua', 'buffers'),
        { desc = 'Find [B]uffer', noremap = true, silent = true }
    )

    map(
        'n',
        '<Leader>fB',
        thunk('fzf-lua', 'builtin'),
        { desc = 'Find [B]uiltin', noremap = true, silent = true }
    )

    map(
        'n',
        '<Leader>fd',
        thunk('fzf-lua', 'diagnostics_document'),
        { desc = 'Find Document [D]iagnostics', noremap = true, silent = true }
    )

    map(
        'n',
        '<Leader>fD',
        thunk('fzf-lua', 'diagnostics_workspace'),
        { desc = 'Find Workspace [D]iagnostics', noremap = true, silent = true }
    )

    map(
        'n',
        '<Leader>fC',
        thunk('fzf-lua', 'highlights'),
        { desc = 'Find Highlight [C]olors', noremap = true, silent = true }
    )

    map(
        'n',
        '<Leader>fgs',
        thunk('fzf-lua', 'git_status'),
        { desc = 'Find [G]it [S]tatus', noremap = true, silent = true }
    )

    map(
        'n',
        '<Leader>fgc',
        thunk('fzf-lua', 'git_commits'),
        { desc = 'Find [G]it [C]ommits', noremap = true, silent = true }
    )

    map('n', '<Leader>fgbc', thunk('fzf-lua', 'git_bcommits'), {
        desc = 'Find [G]it [B]uffer [C]ommits',
        noremap = true,
        silent = true,
    })

    map(
        'n',
        '<Leader>fgbr',
        thunk('fzf-lua', 'git_branches'),
        { desc = 'Find [G]it [BR]anches', noremap = true, silent = true }
    )

    map(
        'n',
        '<Leader>fm',
        thunk('noice.integrations.fzf', 'open'),
        { desc = 'Find Noice [M]sg', noremap = true, silent = true }
    )

    map(
        'n',
        '<Leader>fH',
        thunk('fzf-lua', 'helptags'),
        { desc = 'Find [H]elp Tags', noremap = true, silent = true }
    )

    map(
        'n',
        '<Leader>fT',
        '<cmd>TodoFzfLua<CR>',
        { desc = 'Find [T]odo Items', noremap = true, silent = true }
    )

    map(
        'n',
        '<Leader>f:',
        thunk('fzf-lua', 'command_history'),
        { desc = 'Find Command History', noremap = true, silent = true }
    )

    map(
        'n',
        '<Leader>fR',
        thunk('fzf-lua', 'registers'),
        { desc = 'Find [R]egister', noremap = true, silent = true }
    )

    -- buffer releated, prefix is leader-b
    map(
        'n',
        '<Leader>bc',
        '<cmd>bp | bd #<CR>',
        { desc = 'Buffer [C]lose Current', noremap = true, silent = true }
    )

    map({ 'n', 'v' }, 'j', 'gj', { noremap = true, silent = true })
    map({ 'n', 'v' }, 'k', 'gk', { noremap = true, silent = true })

    map(
        'n',
        '<Leader>h',
        '<cmd>Alpha<CR>',
        { desc = 'Open [H]ome Page', noremap = true, silent = true }
    )

    -- File explorer
    map(
        'n',
        '<leader>e',
        bind(
            thunk('neo-tree.command', 'execute'),
            { action = 'show', source = 'filesystem', toggle = true }
        ),
        {
            desc = 'Toggle File [E]xplorer',
            noremap = true,
            silent = true,
        }
    )

    map(
        'n',
        '<leader>o',
        bind(
            thunk('neo-tree.command', 'execute'),
            { action = 'show', source = 'document_symbols', toggle = true }
        ),
        {
            desc = 'Toggle [O]utline',
            noremap = true,
            silent = true,
        }
    )

    -- Clean search highlight
    map('n', '<Esc>', '<cmd>nohlsearch<CR>', { silent = true })

    -- Delete j and k in select mode
    vim.keymap.del('s', 'j')
    vim.keymap.del('s', 'k')

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

    -- -- insert mode move cursor
    -- map('i', '<C-j>', '<Down>', { noremap = true, silent = true })
    -- map('i', '<C-k>', '<Up>', { noremap = true, silent = true })
    -- map('i', '<C-h>', '<Left>', { noremap = true, silent = true })
    -- map('i', '<C-l>', '<Right>', { noremap = true, silent = true })

    -- Use ctrl-/ to goto normal mode, so weird
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

    -- Tab related
    map(
        { 'n' },
        '<Leader>tt',
        '<cmd>tabnext<cr>',
        { noremap = true, silent = true, desc = '[T]ab switch next' }
    )
    map({ 'n' }, '<Leader>tn', function()
        local name = vim.fn.input('File name: ', '', 'file')
        if name ~= '' then
            vim.cmd('tabnew ' .. name)
        else
            misc.warn 'Warn: Filename not assigned, nothing todo'
        end
    end, { noremap = true, silent = true, desc = 'Tab [N]ew' })
    map(
        { 'n' },
        '<Leader>tp',
        '<cmd>tabprevious<cr>',
        { noremap = true, silent = true, desc = 'Tab [P]revious' }
    )
    map({ 'n' }, '<Leader>ta', '<cmd>tabnew %<cr>', {
        noremap = true,
        silent = true,
        desc = 'Tab [A]dd With Current Buffer',
    })
    map(
        { 'n' },
        '<Leader>tc',
        '<cmd>tabclose<cr>',
        { noremap = true, silent = true, desc = 'Tab [C]lose' }
    )

    map(
        { 'n' },
        '<Leader>lm',
        thunk('mason.ui', 'open'),
        { noremap = true, silent = true, desc = 'Launch Lsp [M]anager' }
    )

    local sandbox = require 'modules.sandbox'.get_mask()
    if sandbox.session then
        -- load the session for the current directory
        map('n', '<leader>sl', function()
            vim.schedule(function()
                local sm = require 'persistence'
                local cache = sm.current()
                if vim.fn.filereadable(cache) ~= 0 then
                    sm.load()
                else
                    misc.warn(
                        'No session in ' .. vim.fn.getcwd(),
                        { title = 'Session Manager' }
                    )
                end
            end)
        end, {
            noremap = true,
            silent = true,
            desc = '[L]oad Last Session Of Current Workspace',
        })

        -- select a session to load
        map(
            'n',
            '<leader>ss',
            thunk('persistence', 'select'),
            { noremap = true, silent = true, desc = '[S]elect Session' }
        )

        -- load the last session
        map(
            'n',
            '<leader>sL',
            bind(thunk('persistence', 'load'), { last = true }),
            { noremap = true, silent = true, desc = '[L]oad Last Session' }
        )

        -- stop Persistence => session won't be saved on exit
        map(
            'n',
            '<leader>sd',
            thunk('persistence', 'stop'),
            { noremap = true, silent = true, desc = "[D]on't Save On Exit" }
        )
    else
        map('n', '<leader>sl', function()
            local oldfiles = vim.v.oldfiles
            for _, file in ipairs(oldfiles) do
                if vim.fn.filereadable(file) == 1 then
                    vim.cmd('edit ' .. vim.fn.fnameescape(file))
                    return
                end
            end
            misc.warn 'No previous file found in v:oldfiles'
        end, {
            noremap = true,
            silent = true,
            desc = 'Recover [L]ast Buffer',
        })
    end

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
end

return M

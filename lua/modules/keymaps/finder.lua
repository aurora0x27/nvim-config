local map = vim.keymap.set
local thunk = require 'utils.loader'.thunk

----------------------------------------------------------------------------
-- Fzflua related, prefix is leader-t
----------------------------------------------------------------------------
map(
    'n',
    '<leader>ff',
    thunk('fzf-lua', 'files'),
    { desc = 'Find [F]iles', noremap = true, silent = true }
)

map(
    'n',
    '<leader>fo',
    thunk('fzf-lua', 'oldfiles'),
    { desc = 'Find [O]ld Files', noremap = true, silent = true }
)

map(
    'n',
    '<leader>ft',
    thunk('fzf-lua', 'treesitter'),
    { desc = 'Find [T]reesitter Symbols', noremap = true, silent = true }
)

map(
    'n',
    '<leader>fw',
    thunk('fzf-lua', 'live_grep'),
    { desc = '[W]ildcard Grep', noremap = true, silent = true }
)

map(
    'n',
    '<leader>fb',
    thunk('fzf-lua', 'buffers'),
    { desc = 'Find [B]uffer', noremap = true, silent = true }
)

map(
    'n',
    '<leader>fB',
    thunk('fzf-lua', 'builtin'),
    { desc = 'Find [B]uiltin', noremap = true, silent = true }
)

map(
    'n',
    '<leader>fd',
    thunk('fzf-lua', 'diagnostics_document'),
    { desc = 'Find Document [D]iagnostics', noremap = true, silent = true }
)

map(
    'n',
    '<leader>fD',
    thunk('fzf-lua', 'diagnostics_workspace'),
    { desc = 'Find Workspace [D]iagnostics', noremap = true, silent = true }
)

map(
    'n',
    '<leader>fC',
    thunk('fzf-lua', 'highlights'),
    { desc = 'Find Highlight [C]olors', noremap = true, silent = true }
)

map(
    'n',
    '<leader>fgs',
    thunk('fzf-lua', 'git_status'),
    { desc = 'Find [G]it [S]tatus', noremap = true, silent = true }
)

map(
    'n',
    '<leader>fgc',
    thunk('fzf-lua', 'git_commits'),
    { desc = 'Find [G]it [C]ommits', noremap = true, silent = true }
)

map('n', '<leader>fgbc', thunk('fzf-lua', 'git_bcommits'), {
    desc = 'Find [G]it [B]uffer [C]ommits',
    noremap = true,
    silent = true,
})

map(
    'n',
    '<leader>fgbr',
    thunk('fzf-lua', 'git_branches'),
    { desc = 'Find [G]it [BR]anches', noremap = true, silent = true }
)

map(
    'n',
    '<leader>fm',
    thunk('noice.integrations.fzf', 'open'),
    { desc = 'Find Noice [M]sg', noremap = true, silent = true }
)

map(
    'n',
    '<leader>fH',
    thunk('fzf-lua', 'helptags'),
    { desc = 'Find [H]elp Tags', noremap = true, silent = true }
)

map(
    'n',
    '<leader>fT',
    thunk('todo-comments.fzf', 'todo'),
    { desc = 'Find [T]odo Items', noremap = true, silent = true }
)

map(
    'n',
    '<leader>f:',
    thunk('fzf-lua', 'command_history'),
    { desc = 'Find Command History', noremap = true, silent = true }
)

map(
    'n',
    '<leader>fR',
    thunk('fzf-lua', 'registers'),
    { desc = 'Find [R]egister', noremap = true, silent = true }
)

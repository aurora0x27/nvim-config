local map = vim.keymap.set
local thunk = require 'utils.loader'.thunk
local bind = require 'utils.loader'.bind

----------------------------------------------------------------------------
-- Fzflua related, prefix is leader-t
----------------------------------------------------------------------------

---@param suffix string
---@param callee string
---@param desc string
local function fzf_mux_map(suffix, callee, desc)
    map(
        'n',
        '<leader>' .. suffix,
        thunk('fzf-lua', callee),
        { desc = desc, noremap = true, silent = true }
    )
    map(
        'n',
        '<leader>tn' .. suffix,
        bind(thunk('fzf-lua', callee), {
            actions = {
                ['default'] = thunk('fzf-lua.actions', 'file_tabedit'),
            },
        }),
        { desc = desc .. ' with [N]ew [T]ab', noremap = true, silent = true }
    )
    map(
        'n',
        '<leader>ws' .. suffix,
        bind(thunk('fzf-lua', callee), {
            actions = {
                ['default'] = thunk('fzf-lua.actions', 'file_split'),
            },
        }),
        {
            desc = '[W]indow [S]plit ' .. desc,
            noremap = true,
            silent = true,
        }
    )
    map(
        'n',
        '<leader>wv' .. suffix,
        bind(thunk('fzf-lua', callee), {
            actions = {
                ['default'] = thunk('fzf-lua.actions', 'file_vsplit'),
            },
        }),
        {
            desc = '[W]indow [V]split ' .. desc,
            noremap = true,
            silent = true,
        }
    )
end

fzf_mux_map('ff', 'files', '[F]iles')
fzf_mux_map('fo', 'oldfiles', '[O]ld Files')
fzf_mux_map('fw', 'live_grep', '[W]ildcard Grep')
fzf_mux_map('fb', 'buffers', '[B]uffers')
fzf_mux_map('fgs', 'git_status', '[G]it [S]tatus')
fzf_mux_map('fH', 'helptags', '[H]elp Tags')

map(
    'n',
    '<leader>ft',
    thunk('fzf-lua', 'treesitter'),
    { desc = '[T]reesitter Symbols', noremap = true, silent = true }
)

map(
    'n',
    '<leader>fB',
    thunk('fzf-lua', 'builtin'),
    { desc = '[B]uiltin', noremap = true, silent = true }
)

map(
    'n',
    '<leader>fd',
    thunk('fzf-lua', 'diagnostics_document'),
    { desc = 'Document [D]iagnostics', noremap = true, silent = true }
)

map(
    'n',
    '<leader>fD',
    thunk('fzf-lua', 'diagnostics_workspace'),
    { desc = 'Workspace [D]iagnostics', noremap = true, silent = true }
)

map(
    'n',
    '<leader>fC',
    thunk('fzf-lua', 'highlights'),
    { desc = 'Highlight [C]olors', noremap = true, silent = true }
)

map(
    'n',
    '<leader>fgc',
    thunk('fzf-lua', 'git_commits'),
    { desc = '[G]it [C]ommits', noremap = true, silent = true }
)

map('n', '<leader>fgbc', thunk('fzf-lua', 'git_bcommits'), {
    desc = '[G]it [B]uffer [C]ommits',
    noremap = true,
    silent = true,
})

map(
    'n',
    '<leader>fgbr',
    thunk('fzf-lua', 'git_branches'),
    { desc = '[G]it [BR]anches', noremap = true, silent = true }
)

map(
    'n',
    '<leader>fm',
    thunk('config.bus.recorder', 'fzf_messages'),
    { desc = 'Noice [M]sg', noremap = true, silent = true }
)

map(
    'n',
    '<leader>f:',
    thunk('fzf-lua', 'command_history'),
    { desc = 'Command History', noremap = true, silent = true }
)

map(
    'n',
    '<leader>fR',
    thunk('fzf-lua', 'registers'),
    { desc = '[R]egister', noremap = true, silent = true }
)

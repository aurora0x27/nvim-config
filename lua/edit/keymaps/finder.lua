local map = vim.keymap.set
local thunk = require 'utils.fnx'.thunk
local bind = require 'utils.fnx'.bind

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
      desc = desc,
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
      desc = desc,
      noremap = true,
      silent = true,
    }
  )
end

fzf_mux_map('ff', 'files', '[F]iles')
fzf_mux_map('fo', 'oldfiles', '[O]ld Files')
fzf_mux_map('fw', 'live_grep', '[W]ildcard Grep')
fzf_mux_map('fb', 'buffers', '[B]uffers')
fzf_mux_map('fgs', 'git_status', '[S]tatus')

----------------------------------------------------------------------------
-- BEGIN Help tags -- cannot use `file_* actions`, should use specified
-- actions
----------------------------------------------------------------------------
map(
  'n',
  '<leader>fH',
  thunk('fzf-lua', 'helptags'),
  { desc = '[H]elp Tags', noremap = true, silent = true }
)
map(
  'n',
  '<leader>tnfH',
  bind(thunk('fzf-lua', 'helptags'), {
    actions = {
      ['default'] = thunk('fzf-lua.actions', 'help_tab'),
    },
  }),
  { desc = '[H]elp Tags with [N]ew [T]ab', noremap = true, silent = true }
)
map('n', '<leader>wsfH', thunk('fzf-lua', 'helptags'), {
  desc = '[H]elp Tags',
  noremap = true,
  silent = true,
})
map(
  'n',
  '<leader>wvfH',
  bind(thunk('fzf-lua', 'helptags'), {
    actions = {
      ['default'] = thunk('fzf-lua.actions', 'help_vert'),
    },
  }),
  {
    desc = '[H]elp Tags',
    noremap = true,
    silent = true,
  }
)
----------------------------------------------------------------------------
-- END Help tags
----------------------------------------------------------------------------

map(
  'n',
  '<leader>ft',
  thunk('fzf-lua', 'treesitter'),
  { desc = '[T]reesitter Symbols', noremap = true, silent = true }
)

map(
  'n',
  '<leader>fT',
  thunk('fzf-lua', 'filetypes'),
  { desc = 'File [T]ypes', noremap = true, silent = true }
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
  { desc = '[C]ommits', noremap = true, silent = true }
)

map('n', '<leader>fgbc', thunk('fzf-lua', 'git_bcommits'), {
  desc = '[C]ommits',
  noremap = true,
  silent = true,
})

map(
  'n',
  '<leader>fgr',
  thunk('fzf-lua', 'git_branches'),
  { desc = 'B[R]anches', noremap = true, silent = true }
)

map(
  'n',
  '<leader>fm',
  thunk('core.bus.backend.recorder', 'fzf_messages'),
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

--------------------------------------------------------------------------------
-- Enhanced git client
--------------------------------------------------------------------------------
local thunk = require 'utils.loader'.thunk
local bind = require 'utils.loader'.bind

---@type LazyPluginSpec
local Neogit = {
  -- TODO: Use official repo after pr merged
  'aurora0x27/neogit',
  enabled = Profile.use_neogit,
  lazy = true,
  dependencies = {
    'ibhagwan/fzf-lua',
  },

  cmd = 'Neogit',

  keys = {
    {
      '<leader>gg',
      thunk('neogit', 'open'),
      desc = 'Show Neogit UI',
    },

    {
      '<leader>tngg',
      bind(thunk('neogit', 'open'), { kind = 'tab' }),
      desc = 'Show Neogit UI',
    },

    {
      '<leader>wsgg',
      bind(thunk('neogit', 'open'), { kind = 'split_below' }),
      desc = 'Show Neogit UI',
    },

    {
      '<leader>wvgg',
      bind(thunk('neogit', 'open'), { kind = 'tab' }),
      desc = 'Show Neogit UI',
    },
  },

  opts = {
    -- Disables changing the buffer highlights based on where the cursor is.
    disable_context_highlighting = true,

    -- Changes what mode the Commit Editor starts in.
    -- `true` will leave nvim in normal mode,
    -- `false` will change nvim to insert mode, and
    -- `"auto"` will change nvim to insert mode IF the commit message is empty,
    -- otherwise leaving it in normal mode.
    disable_insert_on_commit = 'auto',

    -- When enabled, will watch the `.git/` directory for changes and refresh the
    -- status buffer in response to filesystem events.
    filewatcher = {
      interval = 1000,
      enabled = true,
    },

    -- "ascii"   is the graph the git CLI generates
    -- "unicode" is the graph like https://github.com/rbong/vim-flog
    -- "kitty"   is the graph like https://github.com/isakbm/gitgraph.nvim -
    -- use https://github.com/rbong/flog-symbols if you don't use Kitty
    graph_style = 'unicode',

    -- Show relative date by default. When set, use `strftime` to display dates
    commit_date_format = nil,
    log_date_format = nil,

    -- Show message with spinning animation when a git command is running.
    process_spinner = false,

    -- Change the default way of opening neogit
    kind = 'replace',
    -- Floating window style
    floating = {
      relative = 'editor',
      width = 0.8,
      height = 0.8,
      style = 'minimal',
      border = require 'assets.theme'.border,
    },
    -- Disable line numbers
    disable_line_numbers = true,
    -- Disable relative line numbers
    disable_relative_line_numbers = true,
    -- The time after which an output console is shown for slow running commands
    console_timeout = 2000,
    -- Automatically show console if a command takes more than console_timeout milliseconds
    auto_show_console = true,
    -- Automatically close the console if the process exits with a 0 (success) status
    auto_close_console = true,
    notification_icon = '󰊢',
    status = {
      show_head_commit_hash = true,
      recent_commit_count = 10,
      HEAD_padding = 10,
      HEAD_folded = false,
      mode_padding = 3,
      mode_text = {
        M = 'modified',
        N = 'new file',
        A = 'added',
        D = 'deleted',
        C = 'copied',
        U = 'updated',
        R = 'renamed',
        T = 'changed',
        DD = 'unmerged',
        AU = 'unmerged',
        UD = 'unmerged',
        UA = 'unmerged',
        DU = 'unmerged',
        AA = 'unmerged',
        UU = 'unmerged',
        ['?'] = '',
      },
    },

    commit_editor = {
      kind = 'tab',
      show_staged_diff = true,
      -- Accepted values:
      -- "split" to show the staged diff below the commit editor
      -- "vsplit" to show it to the right
      -- "split_above" Like :top split
      -- "vsplit_left" like :vsplit, but open to the left
      -- "auto" "vsplit" if window would have 80 cols, otherwise "split"
      staged_diff_split_kind = 'split',
      spell_check = false,
    },

    commit_select_view = {
      kind = 'tab',
    },
    commit_view = {
      kind = 'vsplit',
      verify_commit = vim.fn.executable('gpg') == 1,
      -- Can be set to true or false, otherwise we try to find the binary
    },
    log_view = {
      kind = 'tab',
    },
    rebase_editor = {
      kind = 'auto',
    },
    reflog_view = {
      kind = 'tab',
    },
    merge_editor = {
      kind = 'auto',
    },
    preview_buffer = {
      kind = 'floating_console',
    },
    popup = {
      kind = 'split',
      show_title = false,
    },
    stash = {
      kind = 'tab',
    },
    refs_view = {
      kind = 'tab',
    },

    signs = {
      -- { CLOSED, OPENED }
      hunk = { '', '' },
      item = { '', '' },
      section = { '', '' },
    },

    -- Each Integration is auto-detected through plugin presence, however, it can be disabled by setting to `false`
    integrations = {
      -- If enabled, uses fzf-lua for menu selection. If the telescope integration
      -- is also selected then telescope is used instead
      -- Requires you to have `ibhagwan/fzf-lua` installed.
      fzf_lua = true,
    },

    -- Which diff viewer to use. nil = auto-detect (tries diffview first, then codediff).
    -- Can be "diffview" or "codediff".
    diff_viewer = nil,
    sections = {
      -- Reverting/Cherry Picking
      sequencer = {
        folded = false,
        hidden = false,
      },
      untracked = {
        folded = false,
        hidden = false,
      },
      unstaged = {
        folded = false,
        hidden = false,
      },
      staged = {
        folded = false,
        hidden = false,
      },
      stashes = {
        folded = true,
        hidden = false,
      },
      unpulled_upstream = {
        folded = true,
        hidden = false,
      },
      unmerged_upstream = {
        folded = false,
        hidden = false,
      },
      unpulled_pushRemote = {
        folded = true,
        hidden = false,
      },
      unmerged_pushRemote = {
        folded = false,
        hidden = false,
      },
      recent = {
        folded = true,
        hidden = false,
      },
      rebase = {
        folded = true,
        hidden = false,
      },
    },
    mappings = {

      commit_editor = {
        ['q'] = 'Close',
        ['C'] = 'Submit',
        ['X'] = 'Abort',
        ['[m'] = 'PrevMessage',
        [']m'] = 'NextMessage',
        ['<leader>mp'] = 'PrevMessage',
        ['<leader>mn'] = 'NextMessage',
        ['<leader>mr'] = 'ResetMessage',
      },

      commit_editor_I = {
        ['<c-c><c-c>'] = 'Submit',
        ['<c-c><c-k>'] = 'Abort',
      },

      rebase_editor = {
        ['p'] = 'Pick',
        ['r'] = 'Reword',
        ['e'] = 'Edit',
        ['s'] = 'Squash',
        ['f'] = 'Fixup',
        ['x'] = 'Execute',
        ['d'] = 'Drop',
        ['b'] = 'Break',
        ['q'] = 'Close',
        ['<cr>'] = 'OpenCommit',
        ['gk'] = 'MoveUp',
        ['gj'] = 'MoveDown',
        ['C'] = 'Submit',
        ['X'] = 'Abort',
        ['[c'] = 'OpenOrScrollUp',
        [']c'] = 'OpenOrScrollDown',
      },

      rebase_editor_I = {
        ['<c-c><c-c>'] = 'Submit',
        ['<c-c><c-k>'] = 'Abort',
      },

      finder = {
        ['<cr>'] = 'Select',
        ['q'] = 'Close',
        [']]'] = 'Next',
        ['[['] = 'Previous',
        ['<down>'] = 'Next',
        ['<up>'] = 'Previous',
        ['<tab>'] = 'InsertCompletion',
        ['<c-y>'] = 'CopySelection',
        ['<space>'] = 'MultiselectToggleNext',
        ['<s-space>'] = 'MultiselectTogglePrevious',
        ['<c-j>'] = 'NOP',
        ['<ScrollWheelDown>'] = 'ScrollWheelDown',
        ['<ScrollWheelUp>'] = 'ScrollWheelUp',
        ['<ScrollWheelLeft>'] = 'NOP',
        ['<ScrollWheelRight>'] = 'NOP',
        ['<LeftMouse>'] = 'MouseClick',
        ['<2-LeftMouse>'] = 'NOP',
      },

      -- Setting any of these to `false` will disable the mapping.
      popup = {
        ['?'] = 'HelpPopup',
        ['A'] = 'CherryPickPopup',
        ['d'] = 'DiffPopup',
        ['M'] = 'RemotePopup',
        ['P'] = 'PushPopup',
        ['X'] = 'ResetPopup',
        ['Z'] = 'StashPopup',
        ['i'] = 'IgnorePopup',
        ['t'] = 'TagPopup',
        ['b'] = 'BranchPopup',
        ['B'] = 'BisectPopup',
        ['w'] = 'WorktreePopup',
        ['c'] = 'CommitPopup',
        ['f'] = 'FetchPopup',
        ['l'] = 'LogPopup',
        ['m'] = 'MergePopup',
        ['p'] = 'PullPopup',
        ['r'] = 'RebasePopup',
        ['v'] = 'RevertPopup',
      },

      status = {
        ['j'] = 'MoveDown',
        ['k'] = 'MoveUp',
        ['o'] = 'OpenTree',
        ['q'] = 'Close',
        ['I'] = 'InitRepo',
        ['1'] = false,
        ['2'] = false,
        ['3'] = false,
        ['4'] = false,
        ['Q'] = 'Command',
        ['<tab>'] = 'Toggle',
        ['za'] = 'Toggle',
        ['zo'] = 'OpenFold',
        ['x'] = 'Discard',
        ['s'] = 'Stage',
        ['S'] = 'StageUnstaged',
        ['<c-s>'] = 'StageAll',
        ['u'] = 'Unstage',
        ['K'] = 'Untrack',
        ['U'] = 'UnstageStaged',
        ['y'] = 'ShowRefs',
        ['$'] = 'CommandHistory',
        ['Y'] = 'YankSelected',
        ['gp'] = 'GoToParentRepo',
        ['<c-r>'] = 'RefreshBuffer',
        ['<cr>'] = 'GoToFile',
        ['<s-cr>'] = 'PeekFile',
        ['<leader>wvo'] = 'VSplitOpen',
        ['<leader>wso'] = 'SplitOpen',
        ['<leader>tno'] = 'TabOpen',
        ['{'] = 'GoToPreviousHunkHeader',
        ['}'] = 'GoToNextHunkHeader',
        ['[c'] = 'OpenOrScrollUp',
        [']c'] = 'OpenOrScrollDown',
        ['<c-up>'] = 'PeekUp',
        ['<c-down>'] = 'PeekDown',
        ['<c-n>'] = 'NextSection',
        ['<c-p>'] = 'PreviousSection',
      },
    },
  },
}

return Neogit

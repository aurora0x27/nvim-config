--------------------------------------------------------------------------------
-- TreeSitter and related
--------------------------------------------------------------------------------

local TSEnsureInstalled = Lang.get_ts_install_list()
local bind = require 'utils.loader'.bind
local thunk = require 'utils.loader'.thunk
local misc = require 'utils.misc'
local LOGTITLE = 'TreeSitter'

---@param args vim.api.keyset.create_autocmd.callback_args
local function safe_ts_start(args)
  local buf = args.buf
  local ft = vim.bo[buf].filetype
  if require 'utils.detect'.is_bigfile(buf) then
    return
  end

  if ft == '' then
    vim.defer_fn(
      bind(
        misc.err,
        'Cannot start parser, ft not assigned',
        { title = LOGTITLE }
      ),
      500
    )
    return
  end

  local ok, lang = pcall(vim.treesitter.language.get_lang, ft)
  if not ok or not lang then
    return
  end

  vim.schedule(function()
    local ok1 = pcall(vim.treesitter.start, buf, lang)
    if not ok1 then
      vim.defer_fn(
        bind(
          misc.err,
          string.format('Cannot start parser for `%s`', lang),
          { title = LOGTITLE }
        ),
        500
      )
    end
    vim.bo.indentexpr = [[v:lua.require'nvim-treesitter'.indentexpr()]]
  end)
end

--------------------------------------------------------------------------------
--- Parser installer
--------------------------------------------------------------------------------

-- TODO: archived, replace with a new fork?
---@type LazyPluginSpec
local TreeSitter = {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  build = ':TSUpdate',
  event = { 'BufReadPre', 'VeryLazy' },
  opts = {
    install_dir = vim.fn.stdpath 'data' .. '/site',
  },
  init = function()
    local langs = Lang.get_ts_enable_langs()
    if #langs ~= 0 then
      vim.api.nvim_create_autocmd({ 'FileType' }, {
        pattern = langs,
        callback = safe_ts_start,
      })
    end
  end,
  config = function(_, opts)
    local TS = require 'nvim-treesitter'
    TS.setup(opts)
    TS.install(TSEnsureInstalled)
  end,
}

--------------------------------------------------------------------------------
--- Textobjects provided by treesitter
--------------------------------------------------------------------------------

---@type LazyPluginSpec
local TreeSitterTextObject = {
  'nvim-treesitter/nvim-treesitter-textobjects',
  branch = 'main',
  event = { 'BufReadPre', 'VeryLazy' },
  init = function()
    -- Disable entire built-in ftplugin mappings to avoid conflicts.
    -- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
    vim.g.no_plugin_maps = true
  end,
  opts = {
    move = {
      -- whether to set jumps in the jumplist
      set_jumps = true,
    },
  },
  keys = {
    {
      'af',
      bind(
        thunk('nvim-treesitter-textobjects.select', 'select_textobject'),
        '@function.outer',
        'textobjects'
      ),
      mode = { 'x', 'o' },
      desc = 'Select around function',
    },
    {
      'if',
      bind(
        thunk('nvim-treesitter-textobjects.select', 'select_textobject'),
        '@function.inner',
        'textobjects'
      ),
      mode = { 'x', 'o' },
      desc = 'Select inner function',
    },

    {
      'ac',
      bind(
        thunk('nvim-treesitter-textobjects.select', 'select_textobject'),
        '@class.outer',
        'textobjects'
      ),
      mode = { 'x', 'o' },
      desc = 'Select around class',
    },
    {
      'ic',
      bind(
        thunk('nvim-treesitter-textobjects.select', 'select_textobject'),
        '@class.inner',
        'textobjects'
      ),
      mode = { 'x', 'o' },
      desc = 'Select inner class',
    },

    {
      'ab',
      bind(
        thunk('nvim-treesitter-textobjects.select', 'select_textobject'),
        '@block.outer',
        'textobjects'
      ),
      mode = { 'x', 'o' },
      desc = 'Select around block',
    },
    {
      'ib',
      bind(
        thunk('nvim-treesitter-textobjects.select', 'select_textobject'),
        '@block.inner',
        'textobjects'
      ),
      mode = { 'x', 'o' },
      desc = 'Select inner block',
    },

    {
      'ai',
      bind(
        thunk('nvim-treesitter-textobjects.select', 'select_textobject'),
        '@conditional.outer',
        'textobjects'
      ),
      mode = { 'x', 'o' },
      desc = 'Select around if stmt',
    },
    {
      'ii',
      bind(
        thunk('nvim-treesitter-textobjects.select', 'select_textobject'),
        '@conditional.inner',
        'textobjects'
      ),
      mode = { 'x', 'o' },
      desc = 'Select inner if stmt',
    },
    {
      'al',
      bind(
        thunk('nvim-treesitter-textobjects.select', 'select_textobject'),
        '@loop.outer',
        'textobjects'
      ),
      mode = { 'x', 'o' },
      desc = 'Select around loop',
    },
    {
      'il',
      bind(
        thunk('nvim-treesitter-textobjects.select', 'select_textobject'),
        '@loop.inner',
        'textobjects'
      ),
      mode = { 'x', 'o' },
      desc = 'Select inner loop',
    },

    {
      ';',
      thunk(
        'nvim-treesitter-textobjects.repeatable_move',
        'repeat_last_move_next'
      ),
      mode = { 'n', 'x', 'o' },
      desc = 'Repeat last move next',
    },
    {
      ',',
      thunk(
        'nvim-treesitter-textobjects.repeatable_move',
        'repeat_last_move_previous'
      ),
      mode = { 'n', 'x', 'o' },
      desc = 'Repeat last move previous',
    },

    {
      'f',
      thunk('nvim-treesitter-textobjects.repeatable_move', 'builtin_f_expr'),
      mode = { 'n', 'x', 'o' },
      expr = true,
    },
    {
      'F',
      thunk('nvim-treesitter-textobjects.repeatable_move', 'builtin_F_expr'),
      mode = { 'n', 'x', 'o' },
      expr = true,
    },
    {
      't',
      thunk('nvim-treesitter-textobjects.repeatable_move', 'builtin_t_expr'),
      mode = { 'n', 'x', 'o' },
      expr = true,
    },
    {
      'T',
      thunk('nvim-treesitter-textobjects.repeatable_move', 'builtin_T_expr'),
      mode = { 'n', 'x', 'o' },
      expr = true,
    },

    {
      ']z',
      bind(
        thunk('nvim-treesitter-textobjects.move', 'goto_next_start'),
        '@fold',
        'folds'
      ),
      mode = { 'n', 'x', 'o' },
      desc = 'Goto next fold point',
    },
  },
}

--------------------------------------------------------------------------------
-- Annotions the scope for current cursor pos context by treesitter
-- Implements sticky buffer
--------------------------------------------------------------------------------

local TreesitterContext = {
  'nvim-treesitter/nvim-treesitter-context',
  enabled = Profile.enable_sticky_buffer,
  event = { 'BufReadPost', 'BufNewFile' },
  opts = {
    multiwindow = true,
  },
}

return { TreeSitter, TreeSitterTextObject, TreesitterContext }

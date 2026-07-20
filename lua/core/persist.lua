--------------------------------------------------------------------------------
-- Persistence
--
-- Manage snapshots of the current working set.
--
-- This module provides a unified persistence layer for editor states, including
-- sessions, undo history, ShaDa and other runtime data. Persistence features
-- are individually configurable through `persist_mode`, while `persist_local`
-- controls whether enabled items are stored globally or isolated inside the
-- current workspace.
--
-- When workspace-local persistence is enabled, data is stored under
-- `persist_local_dir` (relative to the workspace root by default), allowing
-- projects to maintain independent editor state without affecting the global
-- cache.
--
-- Sessions
--
-- Sessions represent snapshots of the current workspace, including opened
-- buffers, window layout and other restorable editor state.
--
-- Every workspace owns one anonymous session (`_`) by default, which is
-- transparently updated on exit and restored on startup. Users may create
-- additional named sessions to preserve multiple working sets for the same
-- project (for example, different tasks or Git branches). Named sessions are
-- managed independently from the anonymous session and are selected explicitly.
--
-- Persist mode:
--   * session  session snapshot
--   * undo     undofile
--   * shada    ShaDa (shared editor state)
--   * swap     swapfile
--   * wb       writebackup
--
-- Profile options:
--   * persist_mode
--       Enable persistence features.
--
--   * persist_local
--       Store selected persistence features inside the current workspace.
--
--   * persist_local_dir
--       Workspace-relative directory used for local persistence storage.
--
-- User events:
--   * PersistSavePre
--   * PersistSavePost
--   * PersistLoadPre
--   * PersistLoadPost
--------------------------------------------------------------------------------
local M = {}

local LOG_TITLE = 'Persistence'
local log = require 'utils.logger'.new(LOG_TITLE)

local PERSIST_MODE_DEFAULTS = {
  session = true,
  undo = true,
  shada = true,
  swap = true,
}

local PERSIST_LOCAL_MODE_DEFAULTS = {
  session = true,
  undo = true,
  shada = true,
  swap = true,
}

local CWD = vim.fn.getcwd()
local PERSIST_LOCAL_DIR_DEFAULT = CWD .. '/.cache/nvim'
local GLOBAL_SESSION_DIR = vim.fn.stdpath('state') .. '/sessions/'
local AUGROUP_NAME = 'Persistence'
local LeastBufferThreshold = 1

local PersistMode = vim.deepcopy(PERSIST_MODE_DEFAULTS)
local PersistLocalMode = vim.deepcopy(PERSIST_LOCAL_MODE_DEFAULTS)
local PersistLocalDir = PERSIST_LOCAL_DIR_DEFAULT

local Activate = false
local SessionName = '_'

local WIN_BORDER = require 'assets.theme'.border

--------------------------------------------------------------------------------
--- Utils
--------------------------------------------------------------------------------
local mangling = require 'utils.mangling'
local parse_featstr = require 'utils.featstr'.parse
local uv = vim.uv
local escape = vim.fn.fnameescape

--- get current branch name
---@return string?
local function branch()
  if uv.fs_stat '.git' then
    local ret = vim.fn.systemlist('git branch --show-current')[1]
    return vim.v.shell_error == 0 and ret or nil
  end
end

local _local_shada_path
---@return string
local function local_shada_path()
  if not _local_shada_path then
    _local_shada_path = PersistLocalDir .. '/shada/main.shada'
  end
  return _local_shada_path
end

local _local_swap_dir
---@return string
local function local_swap_dir()
  if not _local_swap_dir then
    _local_swap_dir = PersistLocalDir .. '/swap//'
  end
  return _local_swap_dir
end

local _local_undo_dir
---@return string
local function local_undo_dir()
  if not _local_undo_dir then
    _local_undo_dir = PersistLocalDir .. '/undo'
  end
  return _local_undo_dir
end

local _local_session_dir
---@return string
local function local_session_dir()
  if not _local_session_dir then
    _local_session_dir = PersistLocalDir .. '/sessions/'
  end
  return _local_session_dir
end

local function fire(event)
  vim.api.nvim_exec_autocmds('User', {
    pattern = 'Persist' .. event,
  })
end

---@param path string
---@return string
local function session_name(path)
  local name = path:match('([^/\\]+)$') or path
  return (name:gsub('%.vim$', ''))
end

---@param dir string
---@return string[]
local function list(dir)
  local sessions = vim.fn.glob(dir .. '/*.vim', true, true)
  table.sort(sessions, function(a, b)
    return uv.fs_stat(a).mtime.sec > uv.fs_stat(b).mtime.sec
  end)
  return sessions
end

--------------------------------------------------------------------------------
--- Public Api
--------------------------------------------------------------------------------

function M.activate()
  if Activate then
    return
  end
  local group = vim.api.nvim_create_augroup(AUGROUP_NAME, { clear = true })
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = group,
    callback = function()
      fire 'SavePre'

      if LeastBufferThreshold > 0 then
        local bufs = vim.tbl_filter(function(b)
          if
            vim.bo[b].buftype ~= ''
            or vim.tbl_contains(
              { 'gitcommit', 'gitrebase', 'jj' },
              vim.bo[b].filetype
            )
          then
            return false
          end
          return vim.api.nvim_buf_get_name(b) ~= ''
        end, vim.api.nvim_list_bufs())
        if #bufs < LeastBufferThreshold then
          return
        end
      end
      M.save()
      fire 'SavePost'
    end,
  })
  Activate = true
end

---@return string
function M.current()
  return SessionName
end

---@param new_name string
function M.rename(new_name)
  assert(#new_name > 0)
  SessionName = new_name
end

function M.deactivate()
  if not Activate then
    return
  end
  pcall(vim.api.nvim_del_augroup_by_name, AUGROUP_NAME)
  Activate = false
end

function M.is_activate()
  return Activate
end

---@class PersistLoadOpt
---@field name? string

---@param opt? PersistLoadOpt
function M.load(opt)
  opt = opt or {}
  if not PersistMode.session then
    log.warn 'Session persistence is not enabled'
    return
  end

  if PersistLocalMode.session then
    local file
    local name
    if opt.name then
      local data = { branch = branch(), name = opt.name }
      file = local_session_dir() .. mangling.encode(data)
      name = opt.name
    else
      local sessions = list(local_session_dir())
      local br = branch()
      for _, spath in ipairs(sessions) do
        local ok, data = pcall(mangling.decode, session_name(spath))
        if ok then
          if br and data['branch'] and br == data['branch'] then
            file = spath
            name = data['name']
            break
          end
        end
      end
    end

    if file and vim.fn.filereadable(file) == 1 then
      fire 'LoadPre'
      vim.cmd('silent! source ' .. escape(file))
      if name then
        SessionName = name
      end
      fire 'LoadPost'
    else
      log.warn 'No session for current working set'
    end
  else
    if opt.name then
      log.warn 'Workspace scope persistence is not enabled\nNeither does named session feature'
    end

    local fname_data = {
      CWD,
      branch = branch(),
    }
    local dir = GLOBAL_SESSION_DIR
    vim.fn.mkdir(dir, 'p')
    local fname = mangling.encode(fname_data) .. '.vim'
    local path = dir .. fname
    if vim.fn.filereadable(path) == 1 then
      fire 'LoadPre'
      vim.cmd('silent! source ' .. escape(path))
      fire 'LoadPost'
    else
      log.warn 'No session for current working set'
    end
  end
end

function M.save()
  if not PersistMode.session then
    return
  end

  if PersistLocalMode.session then
    local fname_data = {
      branch = branch(),
      name = SessionName,
    }
    local dir = local_session_dir()
    vim.fn.mkdir(dir, 'p')
    local fname = mangling.encode(fname_data) .. '.vim'
    vim.cmd('mks! ' .. escape(dir .. fname))
  else
    local fname_data = {
      CWD,
      branch = branch(),
    }
    local dir = GLOBAL_SESSION_DIR
    vim.fn.mkdir(dir, 'p')
    local fname = mangling.encode(fname_data) .. '.vim'
    vim.cmd('mks! ' .. escape(dir .. fname))
  end
end

function M.select()
  if not PersistMode.session then
    log.warn 'Session persistence is not enabled'
    return
  end

  local dir = PersistLocalMode.session and local_session_dir()
    or GLOBAL_SESSION_DIR

  local sessions = list(dir)
  if #sessions == 0 then
    log.warn 'No session found'
    return
  end

  local items = {}
  local lookup = {}

  for _, path in ipairs(sessions) do
    local stem = session_name(path)

    local ok, data = pcall(mangling.decode, stem)
    if ok then
      local label

      if PersistLocalMode.session then
        label = data.name or '_'
        if data.branch then
          label = label .. ' [' .. data.branch .. ']'
        end
      else
        label = data[1] or '?'
        if data.branch then
          label = label .. ' [' .. data.branch .. ']'
        end
      end

      items[#items + 1] = label
      lookup[label] = path
    end
  end

  require 'fzf-lua'.fzf_exec(items, {
    prompt = 'Session> ',
    winopts = {
      height = 0.4,
      width = 0.4,
      row = 0.5,
      col = 0.5,
      border = WIN_BORDER,
    },
    actions = {
      ['default'] = function(selected)
        local path = lookup[selected[1]]
        if not path then
          return
        end

        fire('LoadPre')
        vim.cmd('silent! source ' .. escape(path))

        if PersistLocalMode.session then
          local ok, data = pcall(mangling.decode, session_name(path))
          if ok then
            local name = data.name
            if type(name) == 'string' then
              SessionName = name
            else
              SessionName = '_'
            end
          end
        end

        fire('LoadPost')
      end,

      ['ctrl-x'] = function(selected)
        local path = lookup[selected[1]]
        if not path then
          return
        end

        vim.fn.delete(path)

        local json = path:gsub('%.vim$', '.json')
        if vim.fn.filereadable(json) == 1 then
          vim.fn.delete(json)
        end

        log.info('Deleted session: ' .. selected[1])
      end,
    },
  })
end

--------------------------------------------------------------------------------
--- Setup
--------------------------------------------------------------------------------

local function setup_options()
  if PersistMode.shada then
    if PersistLocalMode.shada then
      vim.o.shadafile = local_shada_path()
    end
  else
    vim.o.shada = ''
  end

  vim.o.swapfile = PersistMode.swap
  if PersistMode.swap and PersistLocalMode.swap then
    vim.o.directory = local_swap_dir()
  end

  vim.o.undofile = PersistMode.undo
  if PersistMode.undo and PersistLocalMode.undo then
    vim.o.undodir = local_undo_dir()
  end
end

function M.setup()
  PersistLocalMode =
    parse_featstr(Profile.persist_local_mode, PersistLocalMode, log.error)
  PersistMode = parse_featstr(Profile.persist_mode, PersistMode, log.error)
  PersistLocalDir = Profile.persist_local_dir
  setup_options()
end

return M

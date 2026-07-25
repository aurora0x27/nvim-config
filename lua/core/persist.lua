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

local CWD = require 'utils.fs'.cwd()
local PERSIST_LOCAL_DIR_DEFAULT = CWD .. '/.cache/nvim'
local GLOBAL_SESSION_ROOT = vim.fn.stdpath('state') .. '/sessions/'
local AUGROUP_NAME = 'Persistence'
local MinBuffersToSave = 1

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
local is_dir = require 'utils.detect'.is_dir
local sprintf = string.format
local summary = require 'utils.strx'.summary

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

local function emit(event)
  vim.api.nvim_exec_autocmds('User', {
    pattern = 'Persist' .. event,
  })
end

---@param path string
---@return string
local function session_name(path)
  local name = path:match('([^/\\]+)$') or path
  return name:gsub('%.vim$', '')
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

local _global_session_dir

---@return string
local function get_session_dir()
  local dir
  if PersistLocalMode.session then
    dir = local_session_dir()
  else
    if not _global_session_dir then
      _global_session_dir = GLOBAL_SESSION_ROOT
        .. mangling.encode { CWD }
        .. '/'
    end
    dir = _global_session_dir
  end
  return dir
end

local floor = math.floor

---@param t integer
---@return string
local function pretty_mtime(t)
  local delta = os.time() - t

  if delta < 60 then
    return 'Just now'
  elseif delta < 3600 then
    return string.format('%dm', floor(delta / 60))
  elseif delta < 86400 then
    return string.format('%dh', floor(delta / 3600))
  elseif delta < 86400 * 7 then
    return string.format('%dd', floor(delta / 86400))
  else
    return os.date('%Y-%m-%d %H:%M', t) --[[@as string]]
  end
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
      if MinBuffersToSave > 0 then
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
        if #bufs < MinBuffersToSave then
          return
        end
      end
      M.save()
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
  if not new_name:match('^[0-9A-Za-z_-]+$') then
    log.error 'Session name may only contain ASCII letters, digits, "_" and "-"'
    return
  end
  SessionName = new_name
end

function M.deactivate()
  if not Activate then
    return
  end
  pcall(vim.api.nvim_del_augroup_by_name, AUGROUP_NAME)
  Activate = false
end

function M.is_active()
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

  local dir = get_session_dir()
  if not is_dir(dir) then
    log.warn 'No sessions for current working set'
    return
  end

  local file
  local name
  if opt.name then
    local data = { branch = branch(), name = opt.name }
    file = dir .. mangling.encode(data)
    name = opt.name
  else
    local sessions = list(dir)
    local br = branch()
    for _, spath in ipairs(sessions) do
      local ok, data = pcall(mangling.decode, session_name(spath))
      if ok then
        if not br or (data['branch'] and br == data['branch']) then
          file = spath
          name = data['name']
          break
        end
      end
    end
  end

  if file and vim.fn.filereadable(file) == 1 then
    emit 'LoadPre'
    vim.cmd('silent! source ' .. escape(file))
    if name then
      SessionName = name
    end
    emit 'LoadPost'
  else
    log.warn 'No session for current working set'
  end
end

function M.save()
  if not PersistMode.session then
    return
  end
  local dir = get_session_dir()
  vim.fn.mkdir(dir, 'p')
  local fname_data = {
    branch = branch(),
    name = SessionName,
  }
  local fname = mangling.encode(fname_data) .. '.vim'
  local path = dir .. fname
  emit 'SavePre'
  vim.cmd('mks! ' .. escape(path))
  emit 'SavePost'
end

function M.select()
  if not PersistMode.session then
    log.warn 'Session persistence is not enabled'
    return
  end

  local dir = get_session_dir()
  if not is_dir(dir) then
    log.warn 'No sessions for current working set'
    return
  end

  local sessions = list(dir)
  if #sessions == 0 then
    log.warn 'No session found'
    return
  end

  local entries = {}

  for _, path in ipairs(sessions) do
    local ok, data = pcall(mangling.decode, session_name(path))
    if ok then
      local stat = uv.fs_stat(path)

      local br = data.branch or '-'
      local name = data.name or '_'

      local time = ''
      if stat then
        time = pretty_mtime(stat.mtime.sec)
      end

      if type(name) ~= 'string' or type(br) ~= 'string' then
        goto continue
      end

      local to_encode = {
        path = path,
        name = name,
        branch = data.branch,
      }

      local encoded = mangling.encode(to_encode)
      local COL_WIDTH = 24
      local label_str = encoded
        .. sprintf(
          '\t%-24s  %-24s  %s',
          summary(name, COL_WIDTH),
          summary(br, COL_WIDTH),
          time
        )

      entries[#entries + 1] = label_str
    end
    ::continue::
  end

  local fzf_ok, Fzf = pcall(require, 'fzf-lua')

  if not fzf_ok then
    log.error "Cannot find fzf-lua module, please ensure it's installed"
    return
  end

  Fzf.fzf_exec(entries, {
    prompt = 'Session> ',
    winopts = {
      height = 0.4,
      width = 0.4,
      row = 0.5,
      col = 0.5,
      border = WIN_BORDER,
    },

    fzf_opts = {
      ['--multi'] = true,
      ['--delimiter'] = '\t',
      ['--with-nth'] = '2..',
      ['--nth'] = '2..',
    },

    actions = {
      ['default'] = function(selected)
        if type(selected) == 'table' then
          assert(#selected >= 1)
          if #selected > 1 then
            log.warn 'Cannot recover multiple sessions, only the 1st is applied'
          end
          selected = selected[1]
        end

        local to_decode = selected:match('^[^\t]+')
        local ok, decoded = pcall(mangling.decode, to_decode)
        if not ok then
          log.error('Cannot decode data because:\n```\n%s\n```', decoded)
          return
        end

        local path = decoded.path
        local br = decoded.branch
        local name = decoded.name

        if
          not path
          or type(path) ~= 'string'
          or not name
          or type(name) ~= 'string'
        then
          log.warn 'Data corruption, cannot apply'
          return
        end

        local stat = uv.fs_stat(path)
        if not stat or stat.type ~= 'file' then
          log.error('Session flie `%s` does not exists', path)
          return
        end

        emit('LoadPre')
        vim.cmd('silent! source ' .. escape(path))
        emit('LoadPost')

        if br then
          log.info(
            'Recovered session `%s` on branch `%s`',
            name == '_' and '*anonymous*' or name,
            br
          )
        else
          log.info(
            'Recovered session `%s`',
            name == '_' and '*anonymous*' or name
          )
        end

        SessionName = name --[[@as string]]
      end,

      ['ctrl-x'] = function(selected)
        local function delete(str)
          local to_decode = str:match('^[^\t]+')
          local ok, decoded = pcall(mangling.decode, to_decode)
          if not ok then
            log.error('Cannot decode data because:\n```\n%s\n```', decoded)
            return
          end

          local path = decoded.path
          local br = decoded.branch
          local name = decoded.name

          if
            not path
            or type(path) ~= 'string'
            or not name
            or type(name) ~= 'string'
          then
            log.warn 'Data corruption, cannot apply'
            return
          end

          vim.fn.delete(path)

          if br then
            log.info(
              'Deleted session `%s` on branch `%s`',
              name == '_' and '*anonymous*' or name,
              br
            )
          else
            log.info(
              'Deleted session `%s`',
              name == '_' and '*anonymous*' or name
            )
          end
        end

        local ty = type(selected)

        if ty == 'table' then
          for _, s in ipairs(selected) do
            delete(s)
          end
        elseif ty == 'string' then
          delete(selected)
        end
      end,
    },
  })
end

---@return {persist_mode: table<string,boolean>, local_mode: table<string, boolean>}
function M.get_modes()
  return {
    persist_mode = PersistMode,
    local_mode = PersistLocalMode,
  }
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

---@class PersistInitOpt
---@field persist_mode?       string
---@field persist_local_mode? string
---@field persist_local_dir?  string

---@param opt? PersistInitOpt
function M.setup(opt)
  opt = opt or {}
  if opt.persist_mode then
    PersistMode = parse_featstr(opt.persist_mode, PersistMode, log.error)
  end
  if opt.persist_local_mode then
    PersistLocalMode =
      parse_featstr(opt.persist_local_mode, PersistLocalMode, log.error)
  end
  if opt.persist_local_dir then
    PersistLocalDir = opt.persist_local_dir
  end
  setup_options()
end

return M

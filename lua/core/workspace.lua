--------------------------------------------------------------------------------
-- Workspace Patch
--
-- Read workspace settings from `.nvim` or `.vscode/nvim`. Propose for the
-- secondary directory is that most projects have `.vscode/` in their gitignores
--------------------------------------------------------------------------------
local M = {}

local workspace_nvim
local workspace_nvimrc
local has_probed = false
local trust_file = vim.fn.stdpath('data') .. '/trusted_workspaces'
local ignore_file = vim.fn.stdpath('data') .. '/ignored_workspaces'
local restrict_mode = true

function M.is_restrict()
  return restrict_mode
end

local uv = vim.uv or vim.loop

local function get_hash(path)
  local stat = uv.fs_stat(path)
  if not stat then
    return vim.fn.sha256(path)
  end
  if stat.type == 'file' then
    local fd = uv.fs_open(path, 'r', 438)
    if not fd then
      return vim.fn.sha256(path)
    end
    local content = uv.fs_read(fd, stat.size, 0)
    uv.fs_close(fd)
    return vim.fn.sha256(path .. content)
  else
    return vim.fn.sha256(path)
  end
end

local function is_trusted(path)
  local stat = uv.fs_stat(trust_file)
  if not stat then
    return false
  end
  local fd = uv.fs_open(trust_file, 'r', 438)
  if not fd then
    return false
  end
  local content = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  if not content then
    return false
  end
  local lines = vim.split(content, '\n')
  local hash = get_hash(path)
  for _, line in ipairs(lines) do
    if line:gsub('%s+', '') == hash then
      return true
    end
  end
  return false
end

local function is_ignored(path)
  local stat = uv.fs_stat(ignore_file)
  if not stat then
    return false
  end
  local fd = uv.fs_open(ignore_file, 'r', 438)
  if not fd then
    return false
  end
  local content = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  if not content then
    return false
  end
  return content:find(get_hash(path)) ~= nil
end

local function trust_path(path)
  local misc = require 'utils.misc'
  local fd = uv.fs_open(trust_file, 'a', 438)
  if not fd then
    misc.err('Cannot open trust file `' .. trust_file .. '`')
    return
  end
  uv.fs_write(fd, get_hash(path) .. '\n')
  uv.fs_close(fd)
  misc.info 'Trusted workspace, allow dofile'
end

local function ignore_path(path)
  local misc = require 'utils.misc'
  local fd = uv.fs_open(ignore_file, 'a', 438)
  if not fd then
    misc.err('Cannot open ignore file `' .. ignore_file .. '`')
    return
  end
  uv.fs_write(fd, get_hash(path) .. '\n')
  uv.fs_close(fd)
  misc.info 'Ignored workspace patch, never notice again'
end

function M.load_main()
  if not workspace_nvim then
    return
  end
  local init_lua = workspace_nvim .. '/init.lua'
  if Profile.workspace_patch_always_restrict then
    restrict_mode = vim.fn.filereadable(init_lua) == 1
    return
  end
  if vim.fn.filereadable(init_lua) == 0 then
    restrict_mode = false
    return
  end
  if is_trusted(init_lua) then
    -- Load module execute main
    local ok, err = pcall(dofile, init_lua)
    if not ok then
      vim.notify(
        'Cannot dofile `' .. init_lua .. '`,\nbecause ' .. err,
        vim.log.levels.ERROR,
        { title = 'Workspace Patch' }
      )
    end
    restrict_mode = false
  elseif is_ignored(init_lua) then
    restrict_mode = true
  else
    -- Popup ui to trust workspace, load fzf to override vim.ui.select
    require 'lazy'.load { plugins = { 'fzf-lua' } }
    vim.ui.select({ 'yes', 'no', 'check' }, {
      prompt = 'Found workspace patch with `init.lua`, trust? ',
    }, function(choice)
      if choice == 'yes' then
        trust_path(init_lua)
        dofile(init_lua)
        restrict_mode = false
        return
      elseif choice == 'no' then
        ignore_path(init_lua)
      elseif choice == 'check' then
        vim.cmd('edit ' .. init_lua)
      end
      restrict_mode = true
    end)
  end
end

---@return string? workspace_nvim, string? workspace_nvimrc
function M.probe()
  if has_probed then
    return workspace_nvim, workspace_nvimrc
  end
  local workspace_patch_dir = vim.fn.getcwd() .. '/.nvim'
  local secondary = vim.fn.getcwd() .. '/.vscode/nvim'
  local has_ws = false
  if vim.fn.isdirectory(workspace_patch_dir) == 1 then
    has_ws = true
  elseif vim.fn.isdirectory(secondary) == 1 then
    workspace_patch_dir = secondary
    has_ws = true
  end
  workspace_nvim = workspace_patch_dir
  local nvimrc_path = workspace_patch_dir .. '/nvimrc.json'
  if has_ws and vim.fn.filereadable(nvimrc_path) == 1 then
    workspace_nvimrc = nvimrc_path
  end
  has_probed = true
  return workspace_nvim, workspace_nvimrc
end

function M.setup()
  if not Profile.allow_workspace_patch then
    return
  end

  if not has_probed then
    M.probe()
  end

  vim.opt.runtimepath:prepend(workspace_nvim)
end

return M

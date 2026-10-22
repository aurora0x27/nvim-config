--------------------------------------------------------------------------------
-- Workspace Patch
--
-- Discover the workspace patch directory and its `nvimrc.json`. Runtime
-- directories are injected into lazy's rtp by `init.lua`.
--
-- `.nvim` is preferred; `.vscode/nvim` is the fallback because most projects
-- already gitignore `.vscode/`.
--------------------------------------------------------------------------------
local M = {}

local uv = assert(vim.uv)

local patch_dir
local local_nvimrc
local has_probed = false

---@return string? patch_dir, string? local_nvimrc
function M.probe()
  if has_probed then
    return patch_dir, local_nvimrc
  end
  local CWD = require 'utils.fs'.cwd()
  local patch_dir_candidates = {
    CWD .. '/.nvim',
    CWD .. '/.vscode/nvim',
  }
  for _, cand in ipairs(patch_dir_candidates) do
    local stat = uv.fs_stat(cand)
    if stat and stat.type == 'directory' then
      patch_dir = cand
      break
    end
  end
  if patch_dir then
    local nvimrc_path = patch_dir .. '/nvimrc.json'
    local stat = uv.fs_stat(nvimrc_path)
    if stat and stat.type == 'file' then
      local_nvimrc = nvimrc_path
    end

    local deprecated_init_lua = uv.fs_stat(patch_dir .. '/init.lua')
    if deprecated_init_lua and deprecated_init_lua.type == 'file' then
      vim.notify(
        'workspace init.lua is no longer supported; move it to `plugin/` or `after/plugin/`',
        vim.log.levels.WARN
      )
    end
  end
  has_probed = true
  return patch_dir, local_nvimrc
end

return M

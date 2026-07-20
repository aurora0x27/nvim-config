--------------------------------------------------------------------------------
-- Lsp installer
--------------------------------------------------------------------------------
local LOG_TITLE = 'Mason'
local log = require 'utils.logger'.new(LOG_TITLE)

local pip_args
local proxy = os.getenv 'PIP_PROXY'
if proxy then
  pip_args = { '--proxy', proxy }
else
  pip_args = {}
end

local LspEnsuredList = Lang.get_mason_install_list()

local function ensure_installed(list)
  local registry = require 'mason-registry'

  local function install_package(pkg_name)
    local ok, pkg = pcall(registry.get_package, pkg_name)
    ---@cast pkg Package
    if not ok then
      log.warn('Package %s not found', pkg_name)
      return
    end
    if not pkg:is_installed() then
      log.info('Installing LSP: ' .. pkg_name)
      pkg:install():once('closed', function()
        if pkg:is_installed() then
          vim.schedule(function()
            log.info('LSP installed: ' .. pkg_name)
          end)
        else
          vim.schedule(function()
            log.error('Failed to install LSP: ' .. pkg_name)
          end)
        end
      end)
    end
  end

  if not registry.refresh then
    -- Old Mason version fallback
    for _, name in ipairs(list) do
      install_package(name)
    end
  else
    -- Newer Mason: async registry refresh
    registry.refresh(function()
      for _, name in ipairs(list) do
        install_package(name)
      end
    end)
  end
end

local Icons = { ui = require 'assets.icons'.get 'ui' }

---@module 'mason'
---@type MasonSettings
local MasonOpt = {
  pip = {
    upgrade_pip = false,
    install_args = pip_args,
  },
  ui = {
    border = 'rounded',
    width = 0.8,
    height = 0.8,
    backdrop = 100,
    icons = {
      package_installed = Icons.ui.Check,
      package_pending = Icons.ui.CloudDownload,
      package_uninstalled = Icons.ui.Circle,
    },
  },
}

-- Mason config table
---@type LazyPluginSpec
local Mason = {
  'williamboman/mason.nvim',
  event = { 'BufReadPre', 'VeryLazy' },
  cmd = { 'Mason' },
  config = function()
    require 'mason'.setup(MasonOpt)
    vim.schedule(require 'utils.fnx'.bind(ensure_installed, LspEnsuredList))
    require 'edit.lsp'.setup()
  end,
}

return Mason

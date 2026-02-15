-- Mason: lsp installer

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local pip_args
local proxy = os.getenv 'PIP_PROXY'
if proxy then
    pip_args = { '--proxy', proxy }
else
    pip_args = {}
end

local LspEnsuredList = {
    vim.g.use_emmylua_ls and 'emmylua_ls' or 'lua-language-server',
    'stylua',
    'pyright',
    'neocmakelsp',
    'prettier',
    'nginx-config-formatter',
    vim.g.enable_gopls and 'gopls' or nil,
    vim.g.enable_jdtls and 'jdtls' or nil,
}

local tools = require 'utils.tools'

local function ensure_installed(list)
    local registry = require 'mason-registry'

    local function install_package(pkg_name)
        local ok, pkg = pcall(registry.get_package, pkg_name)
        ---@cast pkg Package
        if not ok then
            tools.warn(('Package %s not found'):format(pkg_name), { title = 'Mason' })
            return
        end
        if not pkg:is_installed() then
            tools.info('Installing LSP: ' .. pkg_name, { title = 'Mason' })
            pkg:install():once('closed', function()
                if pkg:is_installed() then
                    vim.schedule(function()
                        tools.info('LSP installed: ' .. pkg_name, { title = 'Mason' })
                    end)
                else
                    vim.schedule(function()
                        tools.err('Failed to install LSP: ' .. pkg_name, { title = 'Mason' })
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
            package_installed = '',
            package_pending = '󰁔',
            package_uninstalled = '',
        },
    },
}

-- Mason config table
---@type LazyPluginSpec
local Mason = {
    'williamboman/mason.nvim',
    event = 'VeryLazy',
    cmd = { 'Mason' },
    config = function()
        require('mason').setup(MasonOpt)
        ensure_installed(LspEnsuredList)
    end,
}

return Mason

-- Mason: lsp installer

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local pip_args
local proxy = os.getenv 'PIP_PROXY'
if proxy then
    pip_args = { '--proxy', proxy }
else
    pip_args = {}
end

local function ensure_installed(list)
    local registry = require 'mason-registry'

    local function install_package(pkg_name)
        local ok, pkg = pcall(registry.get_package, pkg_name)
        if not ok then
            vim.notify(('Package %s not found'):format(pkg_name), vim.log.levels.WARN)
            return
        end
        if not pkg:is_installed() then
            vim.notify('Installing LSP: ' .. pkg_name, vim.log.levels.INFO)
            pkg:install():once('closed', function()
                if pkg:is_installed() then
                    vim.schedule(function()
                        vim.notify('LSP installed: ' .. pkg_name, vim.log.levels.INFO)
                    end)
                else
                    vim.schedule(function()
                        vim.notify('Failed to install LSP: ' .. pkg_name, vim.log.levels.ERROR)
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
            package_installed = '✓',
            package_pending = '➜',
            package_uninstalled = '✗',
        },
    },
}

-- Mason config table
---@diagnostic disable: unused-local
local Mason = {
    'williamboman/mason.nvim',
    event = 'VimEnter',
    config = function()
        require('mason').setup(MasonOpt)
        ensure_installed {
            'lua-language-server',
            'stylua',
            'pyright',
            'neocmakelsp',
        }
    end,
}

return Mason

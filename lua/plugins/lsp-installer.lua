-- Mason: lsp installer

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local pip_args
local proxy = os.getenv 'PIP_PROXY'
if proxy then
    pip_args = { '--proxy', proxy }
else
    pip_args = {}
end

local ensure_installed = function(list)
    local registry = require 'mason-registry'
    registry.update(function()
        for _, lsp in ipairs(list) do
            if not registry.is_installed(lsp) then
                registry.get_package(lsp):install()
                print('Installed lsp: ', lsp)
            end
        end
    end)
end

local MasonOpt = {
    pip = {
        upgrade_pip = false,
        install_args = pip_args,
    },
    ui = {
        border = 'rounded',
        width = 0.7,
        height = 0.7,
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
    event = { 'VimEnter' },
    config = function()
        require('mason').setup(MasonOpt)
        ensure_installed {
            'lua-language-server',
            'pyright',
        }
    end,
}

return Mason

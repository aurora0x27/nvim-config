-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local pip_args
local proxy = os.getenv 'PIP_PROXY'
if proxy then
    pip_args = { '--proxy', proxy }
else
    pip_args = {}
end

-- Mason config table
---@diagnostic disable: unused-local
local Mason = {
    'williamboman/mason.nvim',
    -- TODO: Add some default lsp
    event = { 'VimEnter' },
    opts = {
        pip = {
            upgrade_pip = false,
            install_args = pip_args,
        },
        ui = {
            border = 'rounded',
            width = 0.7,
            height = 0.7,
            icons = {
                package_installed = "✓",
                package_pending = "➜",
                package_uninstalled = "✗"
            },
        },
    },
}

return Mason

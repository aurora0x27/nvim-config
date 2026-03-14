--------------------------------------------------------------------------------
-- Workspace Patch
--
-- Read workspace settings from `.nvim` or `.vscode/nvim`. Propose for the
-- secondary directory is that most projects have `.vscode/` in their gitignores
--------------------------------------------------------------------------------
local M = {}

local profile = require 'modules.profile'

local workspace_nvim
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
    return content:find(get_hash(path)) ~= nil
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
    if profile.workspace_patch_always_restrict then
        restrict_mode = true
        return
    end
    local init_lua = workspace_nvim .. '/init.lua'
    if vim.fn.filereadable(init_lua) == 0 then
        restrict_mode = false
        return
    end
    if is_trusted(init_lua) then
        -- Load module execute main
        dofile(init_lua)
        restrict_mode = false
    elseif is_ignored(init_lua) then
        restrict_mode = true
    else
        -- Popup ui to trust workspace, load fzf to override vim.ui.select
        require 'lazy'.load { plugins = { 'fzf-lua' } }
        vim.ui.select({ 'yes', 'no', 'check' }, {
            prompt = 'Found workspace patch with `init.lua`, trust?',
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

---@return string?
function M.setup()
    if not profile.allow_workspace_patch then
        return
    end

    workspace_nvim = vim.fn.getcwd() .. '/.nvim'
    local secondary = vim.fn.getcwd() .. '/.vscode/nvim'
    if vim.fn.isdirectory(workspace_nvim) ~= 1 then
        if vim.fn.isdirectory(secondary) == 1 then
            workspace_nvim = secondary
        else
            return
        end
    end

    vim.opt.runtimepath:prepend(workspace_nvim)
    return workspace_nvim
end

return M

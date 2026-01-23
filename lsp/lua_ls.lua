-- Lua lsp

local lua_ls = {
    cmd = { 'lua-language-server' },
    filetypes = { 'lua' },
    root_markers = { '.git', 'stylua.toml', '.luarc.json' },
    settings = {
        Lua = {
            runtime = {
                version = 'LuaJIT',
            },
        },
    },
}

--- @return string|nil
local function detect_config_file()
    if vim.fn.filereadable '.emmyrc.json' == 1 then
        return '.emmyrc.json'
    elseif vim.fn.filereadable '.luarc.json' == 1 then
        return '.luarc.json'
    end
    return nil
end

---@return table
local function load_workspace_emmyrc_config()
    local ws_cfg = detect_config_file()
    if ws_cfg ~= nil then
        local data = ''
        local lines = vim.fn.readfile(ws_cfg)
        for _, line in ipairs(lines) do
            data = data .. line
        end
        local ok, ret = pcall(vim.json.decode, data)
        if not ok or ret == vim.NIL or type(ret) ~= 'table' then
            vim.defer_fn(function()
                vim.notify(('Failed to parse %s:\n%s'):format(ws_cfg, ret), vim.log.levels.WARN)
            end, 100)
            return {}
        end
        return ret
    end
    return {}
end

---@brief
---
--- https://github.com/EmmyLuaLs/emmylua-analyzer-rust
---
--- Emmylua Analyzer Rust. Language Server for Lua.
---
--- `emmylua_ls` can be installed using `cargo` by following the instructions[here]
--- (https://github.com/EmmyLuaLs/emmylua-analyzer-rust?tab=readme-ov-file#install).
---
--- The default `cmd` assumes that the `emmylua_ls` binary can be found in `$PATH`.
--- It might require you to provide cargo binaries installation path in it.
---@type vim.lsp.Config
local emmylua_ls = {
    cmd = { 'emmylua_ls' },
    filetypes = { 'lua' },
    root_markers = {
        '.luarc.json',
        '.emmyrc.json',
        '.luacheckrc',
        '.git',
    },
    -- -- JSON CONFIG EMBEDDED IN LUA
    -- {
    --   "$schema": "https://raw.githubusercontent.com/EmmyLuaLs/emmylua-analyzer-rust/refs/heads/main/crates/emmylua_code_analysis/resources/schema.json",
    --   "runtime": {
    --     "version": "LuaJIT",
    --     "requirePattern": [
    --       "lua/?.lua",
    --       "lua/?/init.lua",
    --       "?/lua/?.lua",
    --       "?/lua/?/init.lua"
    --     ]
    --   },
    --   "workspace": {
    --     "library": [
    --       "$VIMRUNTIME",
    --       "$LLS_Addons/luvit",
    --     ],
    --     "ignoreGlobs": ["**/*_spec.lua"]
    --   },
    --   "codeAction": {
    --     "insertSpace": true
    --   },
    --   "strict": {
    --     "typeCall": true,
    --     "arrayIndex": true
    --   }
    -- }
    on_init = function(client)
        -- FIXME: Always load vim api ?
        local workspace_config = load_workspace_emmyrc_config()

        if vim.g.inject_vim_rt then
            local default_data_home = vim.env.HOME .. '/.local/share/nvim/lazy'
            local xdg_data_home = vim.env.XDG_DATA_HOME and (vim.env.XDG_DATA_HOME .. '/nvim/lazy') or default_data_home
            local injected_libs = {
                'lua',
                vim.env.VIMRUNTIME,
                '${3rd}/luv/library',
                '${3rd}/busted/library',
            }
            if vim.g.inject_plugin_path then
                table.insert(injected_libs, xdg_data_home)
            end
            client.config.settings.Lua = vim.tbl_deep_extend('force', workspace_config, {
                runtime = {
                    -- Tell the language server which version of Lua you're using
                    -- (most likely LuaJIT in the case of Neovim)
                    version = 'LuaJIT',
                    requirePattern = {
                        'lua/?.lua',
                        'lua/?/init.lua',
                        '?/lua/?.lua',
                        '?/lua/?/init.lua',
                    },
                },
                -- Make the server aware of Neovim runtime files
                workspace = {
                    checkThirdParty = false,
                    library = injected_libs,
                    ignoreGlobs = {
                        '**/*_spec.lua',
                    },
                },
                codeAction = {
                    insertSpace = true,
                },
                strict = {
                    typeCall = true,
                    arrayIndex = true,
                },
            })
        else
            client.config.settings = workspace_config
        end
    end,
    settings = {
        Lua = {},
    },
    workspace_required = false,
}

if vim.g.use_emmylua_ls then
    return emmylua_ls
else
    return lua_ls
end

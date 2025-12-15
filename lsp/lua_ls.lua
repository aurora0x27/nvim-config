-- Lua lsp

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
    workspace_required = false,
}

local lua_ls = {
    cmd = { 'lua-language-server' },
    filetypes = { 'lua' },
    root_markers = { '.git', 'stylua.toml', '.luarc.json' },
    on_init = function(client)
        if client.workspace_folders then
            local path = client.workspace_folders[1].name
            ---@diagnostic disable: undefined-field
            if
                path ~= vim.fn.stdpath 'config'
                and not (
                    vim.fn.filereadable(path .. '/stylua.toml')
                    or vim.fn.filereadable(path .. '/lazy-lock.json')
                    or vim.fn.filereadable(path .. '/luarc.json')
                    or vim.fn.filereadable(path .. '/.luarc.json')
                    or vim.fn.filereadable(path .. '/.luacheckrc')
                    or vim.fn.filereadable(path .. '/.stylua.toml')
                )
            then
                return
            end
        end

        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
            runtime = {
                -- Tell the language server which version of Lua you're using
                -- (most likely LuaJIT in the case of Neovim)
                version = 'LuaJIT',
            },
            -- Make the server aware of Neovim runtime files
            workspace = {
                checkThirdParty = false,
                library = {
                    vim.env.VIMRUNTIME,
                    -- Depending on the usage, you might want to add additional paths here.
                    -- "${3rd}/luv/library"
                    -- "${3rd}/busted/library",
                },
                -- or pull in all of 'runtimepath'.
                -- NOTE: this is a lot slower and will cause issues when working on your own configuration (see https://github.com/neovim/nvim-lspconfig/issues/3189)
                -- library = vim.api.nvim_get_runtime_file("", true)
            },
        })
    end,
    on_attach = function(client)
        if vim.fn.expand '%:t' == 'xmake.lua' then
            vim.lsp.stop_client(client.id)
            return
        end
    end,
    settings = {
        Lua = {},
    },
}

if vim.g.use_emmylua_ls then
    return emmylua_ls
else
    return lua_ls
end

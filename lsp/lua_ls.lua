-- Lua lsp

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
                    or vim.fn.filereadable(path .. '/.lazy.lua')
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
                    '${3rd}/busted/library',
                    '${3rd}/luv/library',
                },
                -- or pull in all of 'runtimepath'.
                -- NOTE: this is a lot slower and will cause issues when working on your own configuration (see https://github.com/neovim/nvim-lspconfig/issues/3189)
                -- library = vim.api.nvim_get_runtime_file("", true)
            },
        })
    end,
    settings = {
        Lua = {
            runtime = {
                version = 'LuaJIT',
            },
        },
    },
}

return lua_ls

local pip_args
local proxy = os.getenv 'PIP_PROXY'
if proxy then
    pip_args = { '--proxy', proxy }
else
    pip_args = {}
end

return {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPost', 'BufNewFile' },
    cmd = { 'LspInfo', 'LspInstall', 'LspUninstall' },
    dependencies = {
        {
            'williamboman/mason.nvim',
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
                },
            },
        },
    },

    config = function()
        -- put configs here
        local lspconfig = require 'lspconfig'

        vim.lsp.buf.hover {
            border = 'rounded',
            focusable = true,
        }

        -- -- Why it doesn't work????
        -- lspconfig.mappings = {
        --     n = {
        --         ["gd"] = { "<cmd>lua vim.lsp.buf.definition()<CR>", desc = "Goto Definition" },
        --     }
        -- }

        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'LSP Goto Definition', noremap = true, silent = true })
        vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, { desc = 'LSP Rename Symbol', noremap = true, silent = true })

        -- clangd config
        lspconfig.clangd.setup {
            keys = {
                -- { "<leader>l", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header (C/C++)" },
            },
            root_dir = function(fname)
                return require('lspconfig.util').root_pattern(
                    'Makefile',
                    'configure.ac',
                    'configure.in',
                    'config.h.in',
                    'meson.build',
                    'meson_options.txt',
                    'build.ninja'
                )(fname) or require('lspconfig.util').root_pattern('compile_commands.json', 'compile_flags.txt')(fname) or require(
                    'lspconfig.util'
                ).find_git_ancestor(fname)
            end,
            capabilities = {
                offsetEncoding = { 'utf-8' },
            },
            cmd = {
                'clangd',
                '--background-index',
                '--clang-tidy',
                '--header-insertion=iwyu',
                '--completion-style=detailed',
                '--function-arg-placeholders',
                '-j=4',
                '--fallback-style="{BasedOnStyle: LLVM, IndentWidth: 4}"',
            },
            init_options = {
                usePlaceholders = true,
                completeUnimported = true,
                clangdFileStatus = true,
            },
        }

        lspconfig.lua_ls.setup {
            on_init = function(client)
                if client.workspace_folders then
                    local path = client.workspace_folders[1].name
                    if path ~= vim.fn.stdpath 'config' and (vim.loop.fs_stat(path .. '/.luarc.json') or vim.loop.fs_stat(path .. '/.luarc.jsonc')) then
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

        lspconfig.rust_analyzer.setup {
            settings = {
                ['rust_analyzer'] = {
                    diagnostics = {
                        enable = true,
                        experimental = {
                            enable = true,
                        },
                    },
                    check = {
                        command = 'clippy',
                        extraArgs = { '--all-targets' },
                        on = 'on_type',
                    },
                    cargo = {
                        buildScripts = {
                            enable = true,
                        },
                    },
                    proMacro = {
                        enable = true,
                    },
                },
            },
            capabilities = {
                experimental = {
                    serverStatusNotification = false,
                },
            },
            cmd = {
                'rust-analyzer',
            },
        }

        lspconfig.pyright.setup {}
    end,
}

return {
    apply = function()
        vim.lsp.enable 'lua_ls'
        vim.lsp.enable 'clangd'
        vim.lsp.enable 'rust_analyzer'
        vim.lsp.enable 'pyright'
        -- vim.lsp.enable 'clice'

        vim.api.nvim_create_autocmd('LspAttach', {
            group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
            callback = function(event)
                ---@diagnostic disable: unused-local
                local client = vim.lsp.get_client_by_id(event.data.client_id)
                vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'LSP Goto Definition', noremap = true, silent = true })
                vim.keymap.set('n', 'gD', vim.lsp.buf.definition, { desc = 'LSP Goto Declaration', noremap = true, silent = true })
                vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, { desc = 'LSP Rename Symbol', noremap = true, silent = true })
            end,
        })
    end,
}

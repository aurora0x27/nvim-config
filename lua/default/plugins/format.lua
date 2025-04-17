-- Format code

return {
    'stevearc/conform.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {},

    config = function()
        require('conform').setup {
            formatters_by_ft = {
                lua = { 'stylua' },
                cpp = { 'clang-format' },
                c = { 'clang-format' },
            },
        }

        vim.api.nvim_create_user_command('Format', function()
            require('conform').format { async = true, lsp_fallback = true }
        end, { desc = 'Format Current Buffer' })
    end,
}

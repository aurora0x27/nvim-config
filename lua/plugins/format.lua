-- Format code

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local CodeFormatter = {
    'stevearc/conform.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
        formatters_by_ft = {
            lua = { 'stylua' },
            cpp = { 'clang-format' },
            c = { 'clang-format' },
            json = { 'prettier' },
            jsonc = { 'prettier' },
            html = { 'prettier' },
            css = { 'prettier' },
            astro = { 'prettier' },
            typescript = { 'prettier' },
            javascript = { 'prettier' },
        },
    },
    config = function(_, opts)
        require('conform').setup(opts)

        local do_format = function()
            require('conform').format { async = true, lsp_fallback = true }
        end

        vim.keymap.set(
            'n',
            '<leader>lf',
            do_format,
            { desc = '[F]ormat Current Buffer', noremap = true, silent = true }
        )

        vim.api.nvim_create_user_command('Format', do_format, { desc = 'Format Current Buffer' })
    end,
}

return CodeFormatter

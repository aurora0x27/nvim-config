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

            formatters = {

                -- use clang-format 20 for clice dev, arch linux updates llvm so damn late
                ['clang-format'] = {
                    meta = {
                        url = 'https://clang.llvm.org/docs/ClangFormat.html',
                        description = 'Tool to format C/C++/… code according to a set of rules and heuristics.',
                    },
                    command = '/home/aurora/Applications/apps/opt/llvm-20/bin/clang-format',
                    args = { '-assume-filename', '$FILENAME' },
                    range_args = function(self, ctx)
                        local start_offset, end_offset = util.get_offsets_from_range(ctx.buf, ctx.range)
                        local length = end_offset - start_offset
                        return {
                            '-assume-filename',
                            '$FILENAME',
                            '--offset',
                            tostring(start_offset),
                            '--length',
                            tostring(length),
                        }
                    end,
                },
            },
        }

        local do_format = function()
            require('conform').format { async = true, lsp_fallback = true }
        end

        vim.keymap.set('n', '<leader>lf', do_format, { desc = 'Format Current Buffer', noremap = true, silent = true })

        vim.api.nvim_create_user_command('Format', do_format, { desc = 'Format Current Buffer' })
    end,
}

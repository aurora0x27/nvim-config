local StatusCol = {
    'luukvbaal/statuscol.nvim',
    event = { 'BufReadPost', 'BufNewFile', 'BufReadPre' },
    opts = function()
        local builtin = require 'statuscol.builtin'

        return {
            bt_ignore = { 'nofile', 'terminal' },
            ft_ignore = { 'NeogitStatus' },
            segments = {
                {
                    sign = {
                        name = { '.*' },
                        text = { '.*' },
                        wrap = false,
                        auto = true,
                        colwidth = 1,
                    },
                    condition = {
                        function(args)
                            local s = vim.fn.sign_getplaced(args.buf, { group = '*', lnum = args.lnum })[1].signs
                            return #s > 0
                        end,
                    },
                    click = 'v:lua.ScSa',
                },
                {
                    text = {
                        function(args)
                            return builtin.lnumfunc(args) .. ' '
                        end,
                    },
                    click = 'v:lua.ScLa',
                },
                {
                    text = {
                        function(args)
                            args.fold.close = ''
                            args.fold.open = ''
                            args.fold.sep = ' '
                            return builtin.foldfunc(args) .. ' '
                        end,
                    },
                    click = 'v:lua.ScFa',
                },
            },
        }
    end,
}

return StatusCol

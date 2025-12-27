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
                        namespace = { 'gitsigns' },
                        wrap = false,
                        auto = true,
                        colwidth = 1,
                    },
                    condition = {
                        function()
                            local status = vim.b.gitsigns_status_dict or {}
                            local added = status.added or 0
                            local changed = status.changed or 0
                            local removed = status.removed or 0
                            return added > 0 or changed > 0 or removed > 0
                        end,
                    },
                    click = 'v:lua.ScSa',
                },
                {
                    sign = {
                        namespace = { 'diagnostic/signs' },
                        wrap = false,
                        auto = true,
                        colwidth = 1,
                    },
                    text = {
                        function(args)
                            local lnum = args.lnum - 1
                            local diags = vim.diagnostic.get(args.buf, { lnum = lnum })
                            if #diags == 0 then
                                return ' '
                            end

                            table.sort(diags, function(a, b)
                                return a.severity < b.severity
                            end)

                            local d = diags[1]
                            local map = require('utils.assets').DiagnosticIconMap
                            local icon, hl = unpack(map[d.severity])
                            return ('%%#%s#%s%%*'):format(hl, icon)
                        end,
                    },
                    condition = {
                        function(args)
                            if vim.v.virtnum ~= 0 then
                                return false
                            end

                            local diags = vim.diagnostic.get(args.buf, {
                                lnum = args.lnum - 1,
                            })

                            return #diags > 0
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

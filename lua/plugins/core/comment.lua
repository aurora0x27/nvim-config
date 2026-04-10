--------------------------------------------------------------------------------
-- Render Patterns Comments
--------------------------------------------------------------------------------

---@type LazyPluginSpec
local CommentRenderer = {
    'nvim-mini/mini.hipatterns',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
        local hipatterns = require 'mini.hipatterns'
        local highlighters = {}
        local groups = {
            Fixme = {
                'fix',
                'fixme',
                'xxx',
            },
            Hack = {
                'warn',
                'hack',
                'warning',
            },
            Note = {
                'note',
                'info',
            },
            Todo = {
                'todo',
            },
        }
        for name, words in pairs(groups) do
            local hl = 'MiniHipatterns' .. name
            for _, word in ipairs(words) do
                highlighters['tokens_' .. name .. '_' .. word .. 'upper'] = {
                    pattern = '%f[%w]' .. word:upper() .. ':+',
                    group = hl,
                }
                highlighters['tokens_' .. name .. '_' .. word .. 'lower'] = {
                    pattern = '%f[%w]' .. word:lower() .. ':+',
                    group = hl,
                }
            end
        end
        hipatterns.setup {
            highlighters = vim.tbl_extend('force', highlighters, {
                -- Highlight hex color strings (`#rrggbb`) using that color
                hex_color = hipatterns.gen_highlighter.hex_color(),
            }),
        }
    end,
}

return CommentRenderer

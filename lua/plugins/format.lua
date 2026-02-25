-- Format code

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local bind = require('utils.loader').bind
local thunk = require('utils.loader').thunk

---@type LazyPluginSpec
local CodeFormatter = {
    'stevearc/conform.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
        formatters_by_ft = require('modules.lang').get_formatter_map(),
    },
    config = function(_, opts)
        require('conform').setup(opts)

        local do_format = bind(thunk('conform', 'format'), { async = true, lsp_fallback = true })

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

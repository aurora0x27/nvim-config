-- Tabline

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local Tabline = {
    'akinsho/bufferline.nvim',
    version = '*',
    dependencies = 'nvim-tree/nvim-web-devicons',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
        require('bufferline').setup {
            highlights = require('catppuccin.special.bufferline').get_theme(),
            options = {
                offsets = {
                    {
                        filetype = 'neo-tree',
                        text = 'File Explorer',
                        separator = true,
                        text_align = 'center',
                    },
                    {
                        filetype = 'alpha',
                        text = '',
                        separator = false,
                    },
                },
            },
        }

        vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
            callback = function(args)
                local ft = vim.bo[args.buf].filetype
                if ft == 'alpha' then
                    vim.o.showtabline = 0
                else
                    vim.o.showtabline = 2
                end
            end,
        })

        local mocha = require('catppuccin.palettes').get_palette 'mocha'
        vim.api.nvim_set_hl(0, 'BufferLineIndicatorSelected', { fg = mocha.lavender, bold = true, italic = true })
        vim.api.nvim_set_hl(0, 'BufferLineModified', { fg = mocha.teal, bold = true })
        vim.api.nvim_set_hl(0, 'BufferLineModifiedVisible', { fg = mocha.teal, bold = true })
        vim.api.nvim_set_hl(0, 'BufferLineModifiedSelected', { fg = mocha.teal, bold = true })
    end,
}

return Tabline

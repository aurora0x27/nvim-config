-- Define some behaviors

local autocmd = {}

function autocmd.apply()
    local mocha = require('catppuccin.palettes').get_palette 'mocha'

    -- Highlight yanked text
    vim.api.nvim_create_autocmd('TextYankPost', {
        pattern = '*',
        callback = function()
            vim.highlight.on_yank {
                higroup = 'IncSearch',
                timeout = 200,
            }
        end,
    })

    -- Do not display warnings
    vim.deprecate = function() end

    -- set Blink border highlight
    vim.api.nvim_set_hl(0, 'BlinkCmpMenuBorder', { fg = mocha.blue })
    vim.api.nvim_set_hl(0, 'BlinkCmpDocBorder', { fg = mocha.blue })
    vim.api.nvim_set_hl(0, 'BlinkCmpSignatureHelpBorder', { fg = mocha.blue })
    vim.api.nvim_set_hl(0, 'BlinkCmpDocSeparator', { fg = mocha.blue })
end

return autocmd

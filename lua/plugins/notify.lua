-- Notifier

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local Notifier = {
    'rcarriga/nvim-notify',
    event = 'VeryLazy',
    config = function()
        local mocha = require('catppuccin.palettes').get_palette 'mocha' -- 选择 catppuccin mocha 配色

        local highlights = {
            { 'NotifyERRORBorder', mocha.red },
            { 'NotifyWARNBorder', mocha.yellow },
            { 'NotifyINFOBorder', mocha.blue },
            { 'NotifyDEBUGBorder', mocha.subtext0 },
            { 'NotifyTRACEBorder', mocha.mauve },

            { 'NotifyERRORIcon', mocha.red },
            { 'NotifyWARNIcon', mocha.yellow },
            { 'NotifyINFOIcon', mocha.blue },
            { 'NotifyDEBUGIcon', mocha.subtext0 },
            { 'NotifyTRACEIcon', mocha.mauve },

            { 'NotifyERRORTitle', mocha.red },
            { 'NotifyWARNTitle', mocha.yellow },
            { 'NotifyINFOTitle', mocha.blue },
            { 'NotifyDEBUGTitle', mocha.subtext0 },
            { 'NotifyTRACETitle', mocha.mauve },
        }

        for _, hl in ipairs(highlights) do
            vim.api.nvim_set_hl(0, hl[1], { fg = hl[2] })
        end

        local body_highlights =
            { 'NotifyERRORBody', 'NotifyWARNBody', 'NotifyINFOBody', 'NotifyDEBUGBody', 'NotifyTRACEBody' }

        for _, hl in ipairs(body_highlights) do
            vim.api.nvim_set_hl(0, hl, { link = 'Normal' })
        end

        -- local icons = {
        --     [vim.log.levels.ERROR] = "",
        --     [vim.log.levels.WARN] = "",
        --     [vim.log.levels.INFO] = "",
        --     [vim.log.levels.DEBUG] = "",
        --     [vim.log.levels.TRACE] = "✎",
        -- }
        -- local icon = icons[notif.level] or "󰂚"

        require('notify').setup {
            background_colour = mocha.base,
            fps = 60,
            max_width = 80,
            max_height = 30,
            stages = 'fade_in_slide_out',
            timeout = 3000,
            top_down = true,
            icons = {
                ERROR = '',
                WARN = '',
                INFO = '',
                DEBUG = '',
                TRACE = '✎',
            },
        }

        vim.notify = require 'notify'
    end,
}

return Notifier

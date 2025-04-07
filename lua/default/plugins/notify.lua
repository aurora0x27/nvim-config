-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
    "rcarriga/nvim-notify",
    config = function()

        local mocha = require("catppuccin.palettes").get_palette("mocha") -- 选择 catppuccin mocha 配色

        -- 定义高亮组
        local highlights = {
            { "NotifyERRORBorder", mocha.red },
            { "NotifyWARNBorder", mocha.yellow },
            { "NotifyINFOBorder", mocha.green },
            { "NotifyDEBUGBorder", mocha.subtext0 },
            { "NotifyTRACEBorder", mocha.mauve },

            { "NotifyERRORIcon", mocha.red },
            { "NotifyWARNIcon", mocha.yellow },
            { "NotifyINFOIcon", mocha.green },
            { "NotifyDEBUGIcon", mocha.subtext0 },
            { "NotifyTRACEIcon", mocha.mauve },

            { "NotifyERRORTitle", mocha.red },
            { "NotifyWARNTitle", mocha.yellow },
            { "NotifyINFOTitle", mocha.green },
            { "NotifyDEBUGTitle", mocha.subtext0 },
            { "NotifyTRACETitle", mocha.mauve },
        }

        -- 应用高亮
        for _, hl in ipairs(highlights) do
            vim.api.nvim_set_hl(0, hl[1], { fg = hl[2] })
        end

        -- 让 NotifyBody 继承 Normal
        local body_highlights = { "NotifyERRORBody", "NotifyWARNBody", "NotifyINFOBody", "NotifyDEBUGBody", "NotifyTRACEBody" }
        for _, hl in ipairs(body_highlights) do
            vim.api.nvim_set_hl(0, hl, { link = "Normal" })
        end

        -- 配置 nvim-notify
        require("notify").setup({
            background_colour = mocha.base,
            fps = 60,
            render = "minimal",
            stages = "fade_in_slide_out",
            timeout = 3000,
            top_down = true, -- 让通知从下往上弹出
        })

        vim.notify = require("notify")
    end,
}

-- Add highlight in comments (experimental)

return {
    apply = function()

        local mocha = require("catppuccin.palettes").get_palette("mocha")

        vim.api.nvim_set_hl(0, "TodoComment", { bg = mocha.teal, fg = mocha.base, bold = true })
        vim.api.nvim_set_hl(0, "FixmeComment", { bg = mocha.red, fg = mocha.base, bold = true })
        vim.api.nvim_set_hl(0, "WarnComment", { bg = mocha.yellow, fg = mocha.base,bold = true })
        vim.api.nvim_set_hl(0, "DebugComment", { bg = mocha.blue, fg = mocha.base, bold = true })

        vim.api.nvim_create_autocmd({ "BufReadPost", "BufWinEnter" }, {
            callback = function()
                vim.fn.matchadd("TodoComment", [[\v<(TODO|todo)>]])
                vim.fn.matchadd("FixmeComment", [[\v<(FIXME|fixme)>]])
                vim.fn.matchadd("DebugComment", [[\v<(DEBUG|debug)>]])
                vim.fn.matchadd("WarnComment", [[\v<(WARN|warn)>]])
            end,
        })

    end
}

-- Define some behaviors

local autocmd = {}

function autocmd.apply()

    local mocha = require("catppuccin.palettes").get_palette("mocha")

    -- Highlight yanked text
    vim.api.nvim_create_autocmd("TextYankPost", {
        pattern = "*",
        callback = function()
            vim.highlight.on_yank({
                higroup = "IncSearch",
                timeout = 200,
            })
        end,
    })

    -- Do not display warnings
    vim.deprecate = function() end

    -- -- add border
    -- vim.api.nvim_create_autocmd("LspAttach", {
    --     callback = function(args)
    --         print("Notice callback called")
    --         vim.keymap.set("n", "K", function()
    --             vim.lsp.buf.hover({
    --                 border = "single", -- 强制边框
    --                 focusable = true
    --             })
    --         end, { buffer = args.buf })
    --     end
    -- })

    -- diagnostic info
    vim.diagnostic.config({
        virtual_text = false,
        virtual_lines = {
            only_current_line = true,
            -- severity = { min = vim.diagnostic.severity.WARN }
        },
        underline = true,
        signs = true,
        update_in_insert = false
    })

    -- auto update diagnostic info
    vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"}, {
        callback = function()
            vim.diagnostic.show(nil, 0, nil, { virtual_lines = { only_current_line = true } })
        end
    })


    -- set Blink border highlight
    vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { fg = mocha.blue })
    vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { fg = mocha.blue })
    vim.api.nvim_set_hl(0, "BlinkCmpSignatureHelpBorder", { fg = mocha.blue })
    vim.api.nvim_set_hl(0, "BlinkCmpDocSeparator", { fg = mocha.blue })
end

return autocmd

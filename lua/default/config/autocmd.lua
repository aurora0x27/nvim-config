-- Define some behaviors

local autocmd = {}

function autocmd.apply()
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

end

return autocmd

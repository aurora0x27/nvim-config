-- Define some behaviors

local autocmd = {}

function autocmd.apply()
    -- Highlight yanked text
    vim.api.nvim_create_autocmd("TextYankPost", {
        pattern = "*",
        callback = function()
            vim.highlight.on_yank({
                higroup = "IncSearch",  -- 高亮组，Astronvim 使用 IncSearch
                timeout = 200,          -- 高亮持续时间（毫秒）
            })
        end,
    })

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

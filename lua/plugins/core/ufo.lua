--------------------------------------------------------------------------------
-- Enhanced fold provider
--------------------------------------------------------------------------------
local thunk = require 'utils.loader'.thunk

---@type LazySpec
local Ufo = {
    'kevinhwang91/nvim-ufo',
    enabled = Profile.use_ufo_as_fold_provider,
    dependencies = { 'kevinhwang91/promise-async' },
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
        preview = {
            win_config = {
                border = { '', '─', '', '', '', '─', '', '' },
                winhighlight = 'Normal:Folded',
                winblend = 0,
            },
            mappings = {
                scrollU = '<S-Up>',
                scrollD = '<S-Down>',
                jumpTop = '[',
                jumpBot = ']',
            },
        },

        fold_virt_text_handler = function(
            virtText,
            lnum,
            endLnum,
            width,
            truncate
        )
            local newVirtText = {}
            local suffix = ('   󰁂 [%d lines folded]'):format(endLnum - lnum)
            local sufWidth = vim.fn.strdisplaywidth(suffix)
            local targetWidth = width - sufWidth
            local curWidth = 0
            for _, chunk in ipairs(virtText) do
                local chunkText = chunk[1]
                local chunkWidth = vim.fn.strdisplaywidth(chunkText)
                if targetWidth > curWidth + chunkWidth then
                    table.insert(newVirtText, chunk)
                else
                    chunkText = truncate(chunkText, targetWidth - curWidth)
                    local hlGroup = chunk[2]
                    table.insert(newVirtText, { chunkText, hlGroup })
                    chunkWidth = vim.fn.strdisplaywidth(chunkText)
                    -- str width returned from truncate() may less than 2nd argument, need padding
                    if curWidth + chunkWidth < targetWidth then
                        suffix = suffix
                            .. (' '):rep(targetWidth - curWidth - chunkWidth)
                    end
                    break
                end
                curWidth = curWidth + chunkWidth
            end
            table.insert(newVirtText, { suffix, 'CustomFold' })
            return newVirtText
        end,

        provider_selector = function(_, filetype, buftype)
            local function handleFallbackException(bufnr, err, providerName)
                if
                    type(err) == 'string' and err:match 'UfoFallbackException'
                then
                    return require 'ufo'.getFolds(bufnr, providerName)
                else
                    return require 'promise'.reject(err)
                end
            end

            -- only use indent until a file is opened
            return (filetype == '' or buftype == 'nofile') and 'indent'
                or function(bufnr)
                    return require 'ufo'
                        .getFolds(bufnr, 'lsp')
                        :catch(function(err)
                            return handleFallbackException(
                                bufnr,
                                err,
                                'treesitter'
                            )
                        end)
                        :catch(function(err)
                            return handleFallbackException(bufnr, err, 'indent')
                        end)
                end
        end,
    },

    keys = {
        {
            'zR',
            thunk('ufo', 'openAllFolds'),
            mode = 'n',
        },
        {
            'zr',
            thunk('ufo', 'openFoldsExceptKinds'),
            mode = 'n',
        },
        {
            'zm',
            thunk('ufo', 'closeFoldsWith'),
            mode = 'n',
        },
        {
            'zM',
            thunk('ufo', 'closeAllFolds'),
            mode = 'n',
        },
        {
            'K',
            function()
                local winid = require 'ufo'.peekFoldedLinesUnderCursor()
                if not winid then
                    vim.lsp.buf.hover()
                end
            end,
            mode = 'n',
        },
    },
}

return Ufo

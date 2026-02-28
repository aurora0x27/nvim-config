---@type LazyPluginSpec
local RenderMarkdown = {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
        callout = {
            abstract = {
                raw = '[!ABSTRACT]',
                rendered = '󰯂 Abstract',
                highlight = 'RenderMarkdownInfo',
                category = 'obsidian',
            },
            summary = {
                raw = '[!SUMMARY]',
                rendered = '󰯂 Summary',
                highlight = 'RenderMarkdownInfo',
                category = 'obsidian',
            },
            tldr = { raw = '[!TLDR]', rendered = '󰦩 Tldr', highlight = 'RenderMarkdownInfo', category = 'obsidian' },
            failure = {
                raw = '[!FAILURE]',
                rendered = ' Failure',
                highlight = 'RenderMarkdownError',
                category = 'obsidian',
            },
            fail = { raw = '[!FAIL]', rendered = ' Fail', highlight = 'RenderMarkdownError', category = 'obsidian' },
            missing = {
                raw = '[!MISSING]',
                rendered = ' Missing',
                highlight = 'RenderMarkdownError',
                category = 'obsidian',
            },
            attention = {
                raw = '[!ATTENTION]',
                rendered = ' Attention',
                highlight = 'RenderMarkdownWarn',
                category = 'obsidian',
            },
            warning = {
                raw = '[!WARNING]',
                rendered = ' Warning',
                highlight = 'RenderMarkdownWarn',
                category = 'github',
            },
            danger = {
                raw = '[!DANGER]',
                rendered = ' Danger',
                highlight = 'RenderMarkdownError',
                category = 'obsidian',
            },
            error = {
                raw = '[!ERROR]',
                rendered = ' Error',
                highlight = 'RenderMarkdownError',
                category = 'obsidian',
            },
            bug = { raw = '[!BUG]', rendered = ' Bug', highlight = 'RenderMarkdownError', category = 'obsidian' },
            quote = {
                raw = '[!QUOTE]',
                rendered = ' Quote',
                highlight = 'RenderMarkdownQuote',
                category = 'obsidian',
            },
            cite = { raw = '[!CITE]', rendered = ' Cite', highlight = 'RenderMarkdownQuote', category = 'obsidian' },
            todo = { raw = '[!TODO]', rendered = ' Todo', highlight = 'RenderMarkdownInfo', category = 'obsidian' },
            wip = { raw = '[!WIP]', rendered = '󰦖 WIP', highlight = 'RenderMarkdownHint', category = 'obsidian' },
            done = {
                raw = '[!DONE]',
                rendered = ' Done',
                highlight = 'RenderMarkdownSuccess',
                category = 'obsidian',
            },
        },

        sign = { enabled = false },

        code = {
            -- general
            width = 'block',
            min_width = 120,
            -- borders
            border = 'thin',
            left_pad = 1,
            right_pad = 1,
            -- language info
            position = 'left',
            language_icon = true,
            language_name = true,
            -- avoid making headings ugly
            highlight_inline = 'RenderMarkdownCodeInfo',
            render_modes = true,
        },

        heading = {
            icons = { ' 󰼏 ', ' 󰎨 ', ' 󰼑 ', ' 󰎲 ', ' 󰼓 ', ' 󰎴 ' },
            border = false,
            render_modes = true, -- keep rendering while inserting
            width = 'block',
            min_width = 120,
        },

        dash = {
            enabled = true,
            render_modes = true,
            width = 120,
        },

        bullet = {
            -- Useful context to have when evaluating values.
            -- | level | how deeply nested the list is, 1-indexed          |
            -- | index | how far down the item is at that level, 1-indexed |
            -- | value | text value of the marker node                     |

            -- Turn on / off list bullet rendering
            enabled = true,
            -- Additional modes to render list bullets
            render_modes = true,
            -- Replaces '-'|'+'|'*' of 'list_item'.
            -- If the item is a 'checkbox' a conceal is used to hide the bullet instead.
            -- Output is evaluated depending on the type.
            -- | function   | `value(context)`                                    |
            -- | string     | `value`                                             |
            -- | string[]   | `cycle(value, context.level)`                       |
            -- | string[][] | `clamp(cycle(value, context.level), context.index)` |
            icons = { '●', '○', '◆', '◇' },
            -- Replaces 'n.'|'n)' of 'list_item'.
            -- Output is evaluated using the same logic as 'icons'.
            ordered_icons = function(ctx)
                local value = vim.trim(ctx.value)
                local index = tonumber(value:sub(1, #value - 1))
                return ('%d.'):format(index > 1 and index or ctx.index)
            end,
            -- Padding to add to the left of bullet point.
            -- Output is evaluated depending on the type.
            -- | function | `value(context)` |
            -- | integer  | `value`          |
            left_pad = 0,
            -- Padding to add to the right of bullet point.
            -- Output is evaluated using the same logic as 'left_pad'.
            right_pad = 0,
            -- Highlight for the bullet icon.
            -- Output is evaluated using the same logic as 'icons'.
            highlight = 'RenderMarkdownBullet',
            -- Highlight for item associated with the bullet point.
            -- Output is evaluated using the same logic as 'icons'.
            scope_highlight = {},
        },

        checkbox = {
            render_modes = true,
            unchecked = {
                icon = '',
                highlight = 'RenderMarkdownChecked',
                scope_highlight = 'RenderMarkdownChecked',
            },
            checked = {
                icon = '',
                highlight = 'RenderMarkdownChecked',
                scope_highlight = 'RenderMarkdownChecked',
            },
            custom = {
                question = {
                    raw = '[?]',
                    rendered = '',
                    highlight = 'RenderMarkdownError',
                    scope_highlight = 'RenderMarkdownError',
                },
                todo = {
                    raw = '[>]',
                    rendered = '󰦖',
                    highlight = 'RenderMarkdownInfo',
                    scope_highlight = 'RenderMarkdownInfo',
                },
                canceled = {
                    raw = '[-]',
                    rendered = '󱋬',
                    highlight = 'RenderMarkdownCodeFallback',
                    scope_highlight = '@text.strike',
                },
                important = {
                    raw = '[!]',
                    rendered = '',
                    highlight = 'RenderMarkdownWarn',
                    scope_highlight = 'RenderMarkdownWarn',
                },
                favorite = {
                    raw = '[~]',
                    rendered = '',
                    highlight = 'RenderMarkdownMath',
                    scope_highlight = 'RenderMarkdownMath',
                },
            },
        },

        quote = {
            render_modes = true,
        },

        pipe_table = {
            alignment_indicator = '─',
            border = { '╭', '┬', '╮', '├', '┼', '┤', '╰', '┴', '╯', '│', '─' },
        },

        link = {
            wiki = { icon = ' ', highlight = 'RenderMarkdownWikiLink', scope_highlight = 'RenderMarkdownWikiLink' },
            image = ' ',
            custom = {
                github = { pattern = 'github', icon = ' ' },
                gitlab = { pattern = 'gitlab', icon = '󰮠 ' },
                youtube = { pattern = 'youtube', icon = ' ' },
                cern = { pattern = 'cern.ch', icon = ' ' },
            },
            hyperlink = ' ',
        },

        -- https://github.com/MeanderingProgrammer/render-markdown.nvim/issues/509
        -- win_options = { concealcursor = { rendered = 'nvic' } },
        completions = {
            blink = { enabled = true },
            lsp = { enabled = true },
        },
    },

    ft = { 'markdown' },
}

return RenderMarkdown

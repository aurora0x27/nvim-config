-- Markdown preview

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- install with yarn or npm
local MarkdownPreview = {
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    build = 'cd app && yarn install',

    -- MarkdownPreviewToggle mappings
    keys = {},

    init = function()
        vim.g.mkdp_filetypes = { 'markdown' }
        -- set to 1, nvim will open the preview window after entering the Markdown buffer
        -- default: 0
        vim.g.mkdp_auto_start = 0

        -- set to 1, the nvim will auto close current preview window when changing
        -- from Markdown buffer to another buffer
        -- default: 1
        vim.g.mkdp_auto_close = 0

        -- set to 1, Vim will refresh Markdown when saving the buffer or
        -- when leaving insert mode. Default 0 is auto-refresh Markdown as you edit or
        -- move the cursor
        -- default: 0
        vim.g.mkdp_refresh_slow = 0

        -- set to 1, the MarkdownPreview command can be used for all files,
        -- by default it can be use in Markdown files only
        -- default: 0
        vim.g.mkdp_command_for_global = 0

        -- set to 1, the preview server is available to others in your network.
        -- By default, the server listens on localhost (127.0.0.1)
        -- default: 0
        vim.g.mkdp_open_to_the_world = 0

        -- use custom IP to open preview page.
        -- Useful when you work in remote Vim and preview on local browser.
        -- For more details see: https://github.com/iamcco/markdown-preview.nvim/pull/9
        -- default empty
        vim.g.mkdp_open_ip = ''

        -- specify browser to open preview page
        -- for path with space
        -- valid: `/path/with\ space/xxx`
        -- invalid: `/path/with\\ space/xxx`
        -- default: ''
        vim.g.mkdp_browser = ''

        -- set to 1, echo preview page URL in command line when opening preview page
        -- default is 0
        vim.g.mkdp_echo_preview_url = 0

        -- a custom Vim function name to open preview page
        -- this function will receive URL as param
        -- default is empty
        vim.g.mkdp_browserfunc = ''

        -- options for Markdown rendering
        -- mkit: markdown-it options for rendering
        -- katex: KaTeX options for math
        -- uml: markdown-it-plantuml options
        -- maid: mermaid options
        -- disable_sync_scroll: whether to disable sync scroll, default 0
        -- sync_scroll_type: 'middle', 'top' or 'relative', default value is 'middle'
        --   middle: means the cursor position is always at the middle of the preview page
        --   top: means the Vim top viewport always shows up at the top of the preview page
        --   relative: means the cursor position is always at relative positon of the preview page
        -- hide_yaml_meta: whether to hide YAML metadata, default is 1
        -- sequence_diagrams: js-sequence-diagrams options
        -- content_editable: if enable content editable for preview page, default: v:false
        -- disable_filename: if disable filename header for preview page, default: 0
        -- vim.g.mkdp_preview_options = {
        --     mkit = {},
        --     katex = {},
        --     uml = {},
        --     maid = {},
        --     disable_sync_scroll = 0,
        --     sync_scroll_type = 'middle',
        --     hide_yaml_meta = 1,
        --     sequence_diagrams = {},
        --     flowchart_diagrams = {},
        --     content_editable = "v:false",
        --     disable_filename = 0,
        --     toc = {}
        -- }

        -- use a custom Markdown style. Must be an absolute path
        -- like '/Users/username/markdown.css' or expand('~/markdown.css')
        vim.g.mkdp_markdown_css = ''

        -- use a custom highlight style. Must be an absolute path
        -- like '/Users/username/highlight.css' or expand('~/highlight.css')
        vim.g.mkdp_highlight_css = ''

        -- use a custom port to start server or empty for random
        vim.g.mkdp_port = ''

        -- preview page title
        -- ${name} will be replace with the file name
        vim.g.mkdp_page_title = '「${name}」'

        -- use a custom location for images
        -- vim.g.mkdp_images_path = /home/user/.markdown_images

        -- set default theme (dark or light)
        -- By default the theme is defined according to the preferences of the system
        vim.g.mkdp_theme = 'dark'

        -- combine preview window
        -- default: 0
        -- if enable it will reuse previous opened preview window when you preview markdown file.
        -- ensure to set let g:mkdp_auto_close = 0 if you have enable this option
        vim.g.mkdp_combine_preview = 0

        -- auto refetch combine preview contents when change markdown buffer
        -- only when g:mkdp_combine_preview is 1
        vim.g.mkdp_combine_preview_auto_refresh = 1

        vim.keymap.set(
            'n',
            '<F8>',
            '<cmd>MarkdownPreviewToggle<CR>',
            { desc = 'MarkdownPreviewToggle', noremap = true, silent = true }
        )
        vim.keymap.set(
            'n',
            '<Leader>p',
            '<cmd>MarkdownPreviewToggle<CR>',
            { desc = 'MarkdownPreviewToggle', noremap = true, silent = true }
        )
    end,

    ft = { 'markdown' },
}

local RenderMarkdown = {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown'
    ---@diagnostic disable:undefined-doc-name
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

return { MarkdownPreview, RenderMarkdown }

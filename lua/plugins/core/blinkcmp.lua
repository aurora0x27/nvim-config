--------------------------------------------------------------------------------
-- CodeCompletion: code completor ui
--------------------------------------------------------------------------------

local lazydev_enabled = require 'modules.lang'.is_supported('lua', 'plg')

---@type LazyPluginSpec
local CodeCompletion = {
    'saghen/blink.cmp',
    -- optional: provides snippets for the snippet source
    dependencies = {
        'catppuccin/nvim',
    },

    event = { 'CmdlineEnter', 'BufReadPre', 'BufNewFile' },

    -- use a release tag to download pre-built binaries
    version = '1.*',
    build = not require('modules.profile').blink_use_binary
            and 'cargo build --release'
        or nil,
    -- If you use nix, you can build from source using latest nightly rust with:
    -- build = 'nix run .#build-plugin',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
        keymap = {
            preset = 'default',
            -- Conflict with cursor move under insert mode?
            ['<C-e>'] = { 'hide' },
            ['<Tab>'] = { 'snippet_forward', 'select_next', 'fallback' },
            ['<S-Tab>'] = { 'snippet_backward', 'select_prev', 'fallback' },
            ['<C-p>'] = { 'select_prev', 'show', 'fallback' },
            ['<C-n>'] = { 'select_next', 'show', 'fallback' },
            ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
            ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
            ['<CR>'] = { 'accept', 'fallback' },
        },

        appearance = {
            -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
            -- Adjusts spacing to ensure icons are aligned
            nerd_font_variant = 'normal',
        },

        -- Experimental signature help support
        signature = {
            enabled = true,
            trigger = {
                -- Show the signature help automatically
                enabled = true,
                -- Show the signature help window after typing any of alphanumerics, `-` or `_`
                show_on_keyword = false,
                blocked_trigger_characters = {},
                blocked_retrigger_characters = {},
                -- Show the signature help window after typing a trigger character
                show_on_trigger_character = true,
                -- Show the signature help window when entering insert mode
                show_on_insert = false,
                -- Show the signature help window when the cursor comes after
                -- a trigger character when entering insert mode
                show_on_insert_on_trigger_character = true,
            },
            window = {
                min_width = 1,
                max_width = 100,
                max_height = 10,
                border = require 'config.assets.misc'.border,
                winblend = 0,
                winhighlight = 'Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder',
                scrollbar = false, -- Note that the gutter will be disabled when border ~= 'none'
                -- Which directions to show the window,
                -- falling back to the next direction when there's not enough space,
                -- or another window is in the way
                direction_priority = { 'n', 's' },
                -- Can accept a function if you need more control
                -- direction_priority = function()
                --   if condition then return { 'n', 's' } end
                --   return { 's', 'n' }
                -- end,

                -- Disable if you run into performance issues
                treesitter_highlighting = true,
                show_documentation = true,
            },
        },

        -- (Default) Only show the documentation popup when manually triggered
        completion = {
            menu = {
                border = 'rounded',
                draw = {
                    columns = {
                        { 'kind_icon' },
                        { 'label', 'label_description', gap = 1 },
                        { 'provider' },
                    },
                    components = {
                        provider = {
                            text = function(ctx)
                                return '['
                                    .. ctx.item.source_name:sub(1, 3):upper()
                                    .. ']'
                            end,
                        },
                    },
                },
            },
            documentation = {
                auto_show = true,
                window = {
                    border = 'rounded',
                },
            },
            list = {
                selection = {
                    preselect = false,
                    auto_insert = true,
                },
            },
        },

        -- Default list of enabled providers defined so that you can extend it
        -- elsewhere in your config, without redefining it, due to `opts_extend`
        sources = {
            default = vim.tbl_filter(function(v)
                return v ~= nil
            end, {
                'snippets',
                'lsp',
                'path',
                'buffer',
                lazydev_enabled and 'lazydev' or nil,
            }),
            providers = {
                lazydev = {
                    name = 'Development',
                    module = 'lazydev.integrations.blink',
                    enabled = lazydev_enabled,
                },
                snippets = {
                    opts = {
                        friendly_snippets = false,
                        extended_filetypes = {
                            astro = { 'html' },
                            markdown = { 'blog', 'html' },
                            zsh = { 'sh' },
                            plaintex = { 'latex' },
                            tex = { 'latex' },
                        },
                    },
                },
            },
        },

        -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
        -- You may use a lua implementation instead by using `implementation = "lua"`
        -- or fallback to the lua implementation, when the Rust fuzzy matcher is not available, by using
        -- `implementation = "prefer_rust"`
        --
        -- See the fuzzy documentation for more information
        fuzzy = { implementation = 'prefer_rust_with_warning' },
    },
    opts_extend = { 'sources.default' },
}

return CodeCompletion

-- Catppuccin Mocha scheme

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local transparent_mode = require('modules.profile').transparent_mode

---@type LazyPluginSpec
local ColorScheme = {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    opts = {
        integrations = {
            alpha = true,
            noice = true,
            cmp = true,
            gitsigns = true,
            mason = true,
            nvimtree = true,
            treesitter = true,
            notify = false,
        },

        -- flavour = 'macchiato', -- latte, frappe, macchiato, mocha
        flavour = 'mocha', -- latte, frappe, macchiato, mocha

        background = { -- :h background
            light = 'latte',
            dark = 'mocha',
        },

        transparent_background = transparent_mode, -- disables setting the background color.
        show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
        term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)

        dim_inactive = {
            enabled = false, -- dims the background color of inactive window
            shade = 'dark',
            percentage = 0.15, -- percentage of the shade to apply to the inactive window
        },

        float = {
            transparent = transparent_mode,
        },

        no_italic = false, -- Force no italic
        no_bold = false, -- Force no bold
        no_underline = false, -- Force no underline
        styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
            comments = { 'italic' }, -- Change the style of comments
            conditionals = { 'italic' },
            loops = {},
            functions = {},
            keywords = {},
            strings = {},
            variables = {},
            numbers = {},
            booleans = {},
            properties = {},
            types = {},
            operators = {},
            -- miscs = {}, -- Uncomment to turn off hard-coded styles
        },
        color_overrides = {},
        custom_highlights = {},
        default_integrations = true,
        highlight_overrides = {
            mocha = function(mocha)
                if transparent_mode then
                    return {
                        LineNr = { fg = mocha.overlay2 },
                        NeoTreeTabSeparatorInactive = { fg = mocha.overlay2 },
                        BufferLineBufferVisible = { fg = mocha.overlay2 },
                        BufferLineDuplicateVisible = { fg = mocha.overlay2 },
                        BufferLineDuplicate = { fg = mocha.overlay2 },
                        NoiceCmdlinePopupBorder = { fg = mocha.teal },
                    }
                else
                    return {
                        NormalFloat = { bg = mocha.base },
                        FloatBorder = { bg = mocha.base },
                        NoiceCmdlinePopupBorder = { fg = mocha.teal },
                    }
                end
            end,
        },
    },
    config = function(_, opts)
        require('catppuccin').setup(opts)

        -- setup must be called before loading
        vim.cmd.colorscheme 'catppuccin'
    end,
}

return ColorScheme

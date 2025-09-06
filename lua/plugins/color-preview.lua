-- Preview colors in comments

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local ColorPreview = {
    'norcalli/nvim-colorizer.lua',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
        require('colorizer').setup({ '*' }, {
            RGB = false, -- #RGB hex codes `#EAF`
            RRGGBB = true, -- #RRGGBB hex codes `#39C5BB`, `#66ccff`
            names = false, -- "Name" codes like `Blue`
            RRGGBBAA = true, -- #RRGGBBAA hex codes `#66ccffff`
            rgb_fn = true, -- CSS rgb() and rgba() functions
            hsl_fn = false, -- CSS hsl() and hsla() functions
            css = false, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
            css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
            -- Available modes: foreground, background
            mode = 'background', -- Set the display mode.
        })
    end,
}

return ColorPreview

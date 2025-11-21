local mocha = require('catppuccin.palettes').get_palette 'mocha'

local Colors = {
    -- Accent
    rosewater = mocha.rosewater,
    flamingo = mocha.flamingo,
    pink = mocha.pink,
    mauve = mocha.mauve,
    red = mocha.red,
    maroon = mocha.maroon,
    peach = mocha.peach,
    yellow = mocha.yellow,
    green = mocha.green,
    teal = mocha.teal,
    sky = mocha.sky,
    sapphire = mocha.sapphire,
    blue = mocha.blue,
    lavender = mocha.lavender,
    black = mocha.crust,

    -- Mode colors
    normal = mocha.blue,
    insert = mocha.green,
    visual = mocha.mauve,
    replace = mocha.red,
    command = mocha.teal,
    select = mocha.rosewater,
    text_fg = mocha.text,
    bg = mocha.base,
}

return Colors

local Styles = {
    sbar = {
        list = { '▁▁ ', '▂▂ ', '▃▃ ', '▄▄ ', '▅▅ ', '▆▆ ', '▇▇ ', '██ ' },
        mchar = '▁▁ ',
    },
    moon = {
        list = {
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
        },
        mchar = ' ',
    },
    circle = {
        list = {
            ' ',
            '󰪞 ',
            '󰪞 ',
            '󰪟 ',
            '󰪟 ',
            '󰪠 ',
            '󰪠 ',
            '󰪡 ',
            '󰪡 ',
            '󰪢 ',
            '󰪣 ',
            '󰪣 ',
            '󰪤 ',
            '󰪤 ',
            '󰪥 ',
        },
        mchar = ' ',
    },
}

local function get_style()
    local theme = require('modules.profile').statline_scrollbar_style
    if not Styles[theme] then
        return Styles['moon']
    else
        return Styles[theme]
    end
end

local ScrollBar = {
    static = get_style(),
    provider = function(self)
        local chars = setmetatable(self.list, {
            __index = function()
                return self.mchar
            end,
        })
        local line_ratio = vim.api.nvim_win_get_cursor(0)[1] / vim.api.nvim_buf_line_count(0)
        local position = math.floor(line_ratio * 100)
        local icon = chars[math.floor(line_ratio * #chars)] .. position
        local limit = 2
        if position <= limit or vim.api.nvim_win_get_cursor(0)[1] == 1 then
            return '↑ TOP'
        elseif position >= 99 or (vim.api.nvim_buf_line_count(0) - vim.api.nvim_win_get_cursor(0)[1]) == 1 then
            return '↓ BOT'
        else
            return string.format('%s', icon) .. '%%'
        end
    end,
    hl = { fg = 'rosewater', bold = true },
}

return ScrollBar

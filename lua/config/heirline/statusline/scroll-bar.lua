local ScrollBar = {
    static = {
        sbar = { '▁▁ ', '▂▂ ', '▃▃ ', '▄▄ ', '▅▅ ', '▆▆ ', '▇▇ ', '██ ' },
        spinner = {
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
    },
    provider = function(self)
        -- local chars = setmetatable(self.sbar, {
        --     __index = function()
        --         return '  '
        --     end,
        -- })
        local chars = setmetatable(self.spinner, {
            __index = function()
                return ' '
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

local conditions = require 'heirline.conditions'

-- Lsp status
local LSPInfo = {
    provider = function()
        if conditions.lsp_attached then
            local clients = vim.lsp.get_clients()
            if next(clients) ~= nil then
                return ' 󰒋 ' .. clients[1].name .. ' '
            end
        end
        return '󰒏 '
    end,
    hl = { fg = 'rosewater', bold = true },
}

return LSPInfo

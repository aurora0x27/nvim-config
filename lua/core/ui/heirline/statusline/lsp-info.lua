local conditions = require 'heirline.conditions'
local IconMisc = require 'assets.icons'.get('misc', true)
local IconLspActive = IconMisc.LspAvailable
local IconNoActiveLsp = IconMisc.NoActiveLsp

-- Lsp status
local LSPInfo = {
    provider = function()
        if conditions.lsp_attached then
            local clients =
                vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
            if #clients == 0 then
                return IconNoActiveLsp
            end
            local names = {}
            for _, client in ipairs(clients) do
                table.insert(names, client.name)
            end
            return IconLspActive .. table.concat(names, ', ') .. ' '
        end
    end,
    hl = { fg = 'rosewater', bold = true },
    update = { 'LspAttach', 'LspDetach', 'BufEnter' },
}

return LSPInfo

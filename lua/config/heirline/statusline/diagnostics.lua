local conditions = require 'heirline.conditions'

local Diagnostics = {
    condition = conditions.has_diagnostics,
    init = function(self)
        self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
        self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
        self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
        self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
    end,
    {
        provider = function(self)
            return self.errors > 0 and (' ' .. self.errors .. ' ') or ''
        end,
        hl = { fg = 'red' },
    },
    {
        provider = function(self)
            return self.warnings > 0 and (' ' .. self.warnings .. ' ') or ''
        end,
        hl = { fg = 'yellow' },
    },
    {
        provider = function(self)
            return self.hints > 0 and (' ' .. self.hints .. ' ') or ''
        end,
        hl = { fg = 'green' },
    },
}

return Diagnostics

local conditions = require 'heirline.conditions'

local GitStatus = {
    condition = conditions.is_git_repo,
    init = function(self)
        self.status = vim.b.gitsigns_status_dict or {}
    end,
    {
        provider = function(self)
            local count = self.status.added or 0
            return count > 0 and (' ' .. count .. ' ') or ''
        end,
        hl = { fg = 'green' },
    },
    {
        provider = function(self)
            local count = self.status.changed or 0
            return count > 0 and (' ' .. count .. ' ') or ''
        end,
        hl = { fg = 'yellow' },
    },
    {
        provider = function(self)
            local count = self.status.removed or 0
            return count > 0 and (' ' .. count .. ' ') or ''
        end,
        hl = { fg = 'red' },
    },
    hl = { bg = 'bg' },
}

return GitStatus

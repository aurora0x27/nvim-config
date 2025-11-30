local utils = require 'heirline.utils'

local Spacer = { provider = ' ' }
local function rpad(child)
    return {
        condition = child.condition,
        child,
        Spacer,
    }
end
local function OverseerTasksForStatus(status)
    return {
        condition = function(self)
            return self.tasks[status]
        end,
        provider = function(self)
            return string.format('%s%d', self.symbols[status], #self.tasks[status])
        end,
        --- @diagnostic disable:unused-local
        hl = function(self)
            return {
                fg = utils.get_highlight(string.format('Overseer%s', status)).fg,
            }
        end,
    }
end

local Overseer = {
    condition = function()
        return package.loaded.overseer
    end,
    init = function(self)
        local tasks = require('overseer.task_list').list_tasks { unique = true, include_ephemeral = true }
        local tasks_by_status = require('overseer.util').tbl_group_by(tasks, 'status')
        self.tasks = tasks_by_status
    end,
    static = {
        symbols = {
            ['CANCELED'] = ' ',
            ['FAILURE'] = '󰅚 ',
            ['SUCCESS'] = '󰄴 ',
            ['RUNNING'] = '󰑮 ',
        },
    },

    rpad(OverseerTasksForStatus 'CANCELED'),
    rpad(OverseerTasksForStatus 'RUNNING'),
    rpad(OverseerTasksForStatus 'SUCCESS'),
    rpad(OverseerTasksForStatus 'FAILURE'),
}

return Overseer

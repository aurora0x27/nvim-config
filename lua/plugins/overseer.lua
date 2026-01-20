local tools = require 'utils.tools'

local function overseer_restart_last()
    local overseer = require 'overseer'
    local task_list = require 'overseer.task_list'
    local tasks = overseer.list_tasks {
        status = {
            overseer.STATUS.SUCCESS,
            overseer.STATUS.FAILURE,
            overseer.STATUS.CANCELED,
        },
        sort = task_list.sort_finished_recently,
    }
    if vim.tbl_isempty(tasks) then
        tools.warn('No tasks found', { title = 'Overseer' })
    else
        local most_recent = tasks[1]
        overseer.run_action(most_recent, 'restart')
    end
end

---@type LazyPluginSpec
local Overseer = {
    'stevearc/overseer.nvim',
    lazy = true,
    ---@module 'overseer'
    dependencies = {
        'ibhagwan/fzf-lua',
    },
    cmd = {
        'OverseerRun',
        'OverseerTaskAction',
        'OverseerShell',
        'OverseerToggle',
        'OverseerClose',
        'OverseerOpen',
        'OverseerRestartLast',
    },
    opts = {
        task_list = {
            direction = 'bottom',
        },
        -- Configure the floating window used for task templates that require input
        -- and the floating window used for editing tasks
        form = {
            zindex = 40,
            -- Dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
            -- min_X and max_X can be a single value or a list of mixed integer/float types.
            min_width = 80,
            max_width = 0.9,
            min_height = 10,
            max_height = 0.9,
            border = 'rounded',
            -- Set any window options here (e.g. winhighlight)
            win_opts = {},
        },
        -- Configuration for task floating output windows
        task_win = {
            -- How much space to leave around the floating window
            padding = 6,
            border = 'rounded',
            -- Set any window options here (e.g. winhighlight)
            win_opts = {},
        },
        templates = {
            'builtin',
        },
    },
    config = function(_, opts)
        local overseer = require 'overseer'
        overseer.setup(opts)
        local tbl_loader = require 'utils.loader'
        local templates = tbl_loader.load_module 'config/overseer/template'
        for _, template in ipairs(templates) do
            overseer.register_template(template)
        end
        vim.api.nvim_create_user_command('OverseerRestartLast', overseer_restart_last, {})
    end,
    keys = {
        { '<leader>rr', '<cmd>OverseerRun<cr>', desc = 'Overseer [R]un' },
        { '<leader>rc', '<cmd>OverseerClose<cr>', desc = 'Overseer [C]lose' },
        { '<leader>rl', '<cmd>OverseerToggle<cr>', desc = 'Overseer [L]ist' },
        { '<leader>rt', overseer_restart_last, desc = 'Overseer Res[T]art Last' },
        {
            '<leader>rs',
            function()
                local cmd = vim.fn.input('Shell Cmd: ', '', 'shellcmdline')
                vim.cmd('OverseerShell ' .. cmd)
            end,
            desc = 'Overseer [S]hell',
        },
        { '<leader>ra', '<cmd>OverseerTaskAction<cr>', desc = 'Overseer [A]ction' },
    },
}

return Overseer

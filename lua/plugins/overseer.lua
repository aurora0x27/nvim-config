local Overseer = {
    'aurora0x27/overseer.nvim',
    ---@module 'overseer'
    lazy = true,
    dependencies = {
        'nvim-telescope/telescope.nvim',
    },
    cmd = { 'OverseerRun', 'OverseerTaskAction', 'OverseerShell', 'OverseerToggle', 'OverseerClose', 'OverseerOpen' },
    config = function()
        require('overseer').setup {
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
        }
    end,
    keys = {
        { '<leader>rr', '<cmd>OverseerRun<cr>', desc = 'Overseer [R]un' },
        { '<leader>rc', '<cmd>OverseerClose<cr>', desc = 'Overseer [C]lose' },
        { '<leader>rl', '<cmd>OverseerToggle<cr>', desc = 'Overseer [L]ist' },
        { '<leader>rb', '<cmd>OverseerBuild<cr>', desc = 'Overseer [B]uild' },
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

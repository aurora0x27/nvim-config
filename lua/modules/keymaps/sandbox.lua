local map = vim.keymap.set
local misc = require 'utils.misc'
local thunk = require 'utils.loader'.thunk
local bind = require 'utils.loader'.bind
local sandbox = require 'modules.sandbox'.get_mask()

----------------------------------------------------------------------------
-- Sandbox sessions
----------------------------------------------------------------------------
if sandbox.session then
    -- load the session for the current directory
    map('n', '<leader>sl', function()
        vim.schedule(function()
            local sm = require 'persistence'
            local cache = sm.current()
            if vim.fn.filereadable(cache) ~= 0 then
                sm.load()
            else
                misc.warn(
                    'No session in ' .. vim.fn.getcwd(),
                    { title = 'Session Manager' }
                )
            end
        end)
    end, {
        noremap = true,
        silent = true,
        desc = '[L]oad Last Session Of Current Workspace',
    })

    -- select a session to load
    map(
        'n',
        '<leader>ss',
        thunk('persistence', 'select'),
        { noremap = true, silent = true, desc = '[S]elect Session' }
    )

    -- load the last session
    map(
        'n',
        '<leader>sL',
        bind(thunk('persistence', 'load'), { last = true }),
        { noremap = true, silent = true, desc = '[L]oad Last Session' }
    )

    -- stop Persistence => session won't be saved on exit
    map(
        'n',
        '<leader>sd',
        thunk('persistence', 'stop'),
        { noremap = true, silent = true, desc = "[D]on't Save On Exit" }
    )
else
    map('n', '<leader>sl', function()
        local oldfiles = vim.v.oldfiles
        for _, file in ipairs(oldfiles) do
            if vim.fn.filereadable(file) == 1 then
                vim.cmd('edit ' .. vim.fn.fnameescape(file))
                return
            end
        end
        misc.warn 'No previous file found in v:oldfiles'
    end, {
        noremap = true,
        silent = true,
        desc = 'Recover [L]ast Buffer',
    })
end

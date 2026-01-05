local IMSwitch = {}

local fcitx5_state

local function get_fcitx5_state()
    return tonumber(vim.fn.system('fcitx5-remote'):match '%d')
end

local function register_autocmd()
    fcitx5_state = get_fcitx5_state()
    vim.api.nvim_create_autocmd('InsertLeave', {
        callback = function()
            fcitx5_state = get_fcitx5_state()
            vim.fn.system 'fcitx5-remote -c'
        end,
    })

    vim.api.nvim_create_autocmd('InsertEnter', {
        callback = function()
            if fcitx5_state == 2 then
                vim.fn.system 'fcitx5-remote -o'
            end
        end,
    })
end

function IMSwitch.apply()
    if vim.fn.executable 'fcitx5-remote' == 1 then
        register_autocmd()
    else
        if require('utils.detect').is_unix() then
            vim.schedule(function()
                require('utils.tools').warn('Cannot find `fcitx5-remote`', { title = 'IM Switch' })
            end)
        end
    end
end

return IMSwitch

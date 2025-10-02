-- IME auto switcher

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local Fcitx5 = { 'www9song/fcitx5-nvim-zh', event = { 'BufReadPost', 'BufNewFile' } }

local ImSwitchMac = {
    'keaising/im-select.nvim',
    config = function()
        require('im_select').setup {
            -- IM will be set to `default_im_select` in `normal` mode
            -- For Windows/WSL, default: "1033", aka: English US Keyboard
            -- For macOS, default: "com.apple.keylayout.ABC", aka: US
            -- For Linux, default:
            --               "keyboard-us" for Fcitx5
            --               "1" for Fcitx
            --               "xkb:us::eng" for ibus
            -- You can use `im-select` or `fcitx5-remote -n` to get the IM's name
            default_im_select = 'com.apple.keylayout.ABC',

            -- Can be binary's name, binary's full path, or a table, e.g. 'im-select',
            -- '/usr/local/bin/im-select' for binary without extra arguments,
            -- or { "AIMSwitcher.exe", "--imm" } for binary need extra arguments to work.
            -- For Windows/WSL, default: "im-select.exe"
            -- For macOS, default: "macism"
            -- For Linux, default: "fcitx5-remote" or "fcitx-remote" or "ibus"
            default_command = '/opt/homebrew/bin/im-select',

            -- Restore the default input method state when the following events are triggered
            -- "VimEnter" and "FocusGained" were removed for causing problems, add it by your needs
            set_default_events = { 'InsertLeave', 'VimEnter', 'FocusGained' },

            -- Restore the previous used input method state when the following events
            -- are triggered, if you don't want to restore previous used im in Insert mode,
            -- e.g. deprecated `disable_auto_restore = 1`, just let it empty
            -- as `set_previous_events = {}`
            set_previous_events = { 'InsertEnter', 'VimLeave', 'FocusLost' },

            -- Show notification about how to install executable binary when binary missed
            keep_quiet_on_no_binary = false,

            -- Async run `default_command` to switch IM or not
            async_switch_im = true,
        }

        -- DEBUG
        -- vim.api.nvim_create_autocmd("FocusLost", {
        --     callback = function()
        --         vim.notify("FocusLost triggered", vim.log.levels.INFO)
        --     end,
        -- })
        -- vim.api.nvim_create_autocmd("FocusGained", {
        --     callback = function()
        --         vim.notify("FocusGained triggered", vim.log.levels.INFO)
        --     end,
        -- })
        -- DEBUG
    end,
}

local is_mac = vim.fn.has 'macunix' == 1

local is_linux = vim.fn.has 'unix' == 1 and not is_mac

if is_linux then
    return Fcitx5
elseif is_mac and not vim.g.neovide then
    if vim.fn.executable 'im-select' ~= 1 then
        vim.notify('`im-select` executable not found', vim.log.levels.WARN)
        vim.notify(
            'Please install `im-select` by executing\n```bash\nbrew tab brew tap daipeihust/tap\nbrew install im-select\n```',
            vim.log.levels.INFO
        )
    end
    return ImSwitchMac
else
    vim.notify('No im-switcher is loaded', vim.log.levels.WARN)
    return {}
end

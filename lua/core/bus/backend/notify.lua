--------------------------------------------------------------------------------
-- Toast notifier backend (nvim-notify like)
--------------------------------------------------------------------------------
local toast = require 'core.ui.toast' -- toast.notify, toast.dismiss_all

local M = {}

-- Titles for known message kinds (fallback: 'Messages')
local KIND_TITLE = {
    emsg = 'Error',
    lua_error = 'Lua Error',
    rpc_error = 'RPC Error',
    echoerr = 'Error',
    wmsg = 'Warning',
    bufwrite = 'Write',
    quickfix = 'Quickfix',
    shell_cmd = 'Shell Cmd',
    shell_err = 'Shell Error',
    shell_ret = 'Shell Ret',
    progress = 'Progress',
}

-- Kinds to skip – already handled elsewhere (statusline, cmdline, etc.)
local SKIP_KIND = {
    search_count = true,
    search_cmd = true,
    completion = true,
    wildlist = true,
    showmode = true,
    empty = true,
}

-- Kinds whose notification should always replace the previous one
-- (e.g. echomsg overwrites previous echo messages).
local ALWAYS_REPLACE_CURRENT_KIND = {
    echomsg = true,
    echo = true,
    lua_print = true,
}

-- Mode mapping: some message types naturally append content
local MODE_OF_TAG = {
    ['notify'] = 'replace',
    ['bus'] = 'replace',
    ['msg.show.emsg'] = 'append',
    ['msg.show.echoerr'] = 'append',
    ['msg.show.lua_error'] = 'replace',
    ['msg.show.rpc_error'] = 'replace',
}

---@param msg Message
local function handler(msg)
    -- msg.clear: dismiss all toast windows
    if msg.tag == 'msg.clear' then
        toast.dismiss_all()
        return false
    end

    local content = msg.content
    if not content then
        return false
    end

    --- Resolve notification options
    ---@type ToastNotifyOpts
    local toast_opts = { anchor = 'NE' }

    -- level: used for icon & default highlights
    toast_opts.level = msg.level

    if msg.tag == 'notify' then
        toast_opts = vim.tbl_deep_extend('force', toast_opts, msg.data)
        -- Show the toast (string or chunk list accepted)
        toast.notify(content, toast_opts)
        return false
    end

    local data = msg.data ---@type NvimMsgShowData?
    if not data then
        return false
    end

    local kind = data.kind
    if SKIP_KIND[kind] then
        return false
    end

    -- id: for deduplication / replacement
    if ALWAYS_REPLACE_CURRENT_KIND[kind] then
        -- Always replace the last notification of this kind
        toast_opts.id = kind
    elseif data.replace_last then
        -- Replace the directly preceding notification (identified by message id)
        toast_opts.id = tostring(msg.id)
    end

    -- mode: 'append' grows the existing notification, otherwise full replace
    if data.append then
        toast_opts.mode = 'append'
    else
        toast_opts.mode = MODE_OF_TAG[msg.tag] or 'replace'
    end

    -- title
    toast_opts.title = KIND_TITLE[msg.data.kind] or 'Messages'

    -- Show the toast (string or chunk list accepted)
    toast.notify(content, toast_opts)

    return false -- already handled
end

function M.setup()
    -- Subscribe to all message events we want to display as toasts
    Bus.register_subscriber('notify', {
        exact = {
            'notify',
            'bus',
            'msg.show.emsg',
            'msg.show.echoerr',
            'msg.show.lua_error',
            'msg.show.rpc_error',
            'msg.show.shell_cmd',
            'msg.show.shell_err',
            'msg.show.shell_out',
            'msg.show.shell_ret',
        },
    }, vim.log.levels.TRACE, handler)
end

return M

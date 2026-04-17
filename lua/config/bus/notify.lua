--------------------------------------------------------------------------------
-- Nvim-Notify backend
--------------------------------------------------------------------------------
local layout_chunks = require 'utils.render'.layout_chunks

local M = {}

local UserConfig = {}

--- Build on_open callback that applies extmarks after notify renders the buffer
---@param layout ChunkLayout
---@return fun(buf: integer, notification: notify.Record, highlights: notify.Highlights, config)
local function make_render(layout)
    return function(buf, notification, highlights, config)
        -- notify writes content starting at line 0; find the actual content lines
        local default_render_name = UserConfig.render or 'default'
        local default_render = require('notify.render')[default_render_name]
        default_render(buf, notification, highlights, config)
        local ns = vim.api.nvim_create_namespace 'MessageBusNotify'
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        -- notify prepends decoration lines; scan for our first content line
        local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local offset = 0
        for i, line in ipairs(buf_lines) do
            if line == layout.lines[1] then
                offset = i - 1
                break
            end
        end
        for _, m in ipairs(layout.marks) do
            pcall(
                vim.api.nvim_buf_set_extmark,
                buf,
                ns,
                m.row + offset,
                m.col_start,
                {
                    end_col = m.col_end,
                    hl_group = m.hl,
                    priority = 100,
                }
            )
        end
    end
end

---@class SentMsg
---@field content NvimMsgTuple[]
---@field rec notify.Record

---@type table<integer, SentMsg>  msg.id -> nvim-notify record
local replace_map = {}

---@type table<string, SentMsg>  kind -> current active notify record (for unstable-id kinds)
local kind_active = {}

--- kinds whose nvim id is unstable across emissions, must replace by kind
local ALWAYS_REPLACE_CURRENT_KIND = {
    echomsg = true,
    echo = true,
    lua_print = true,
}

local KIND_TITLE = {
    emsg = 'Error',
    lua_error = 'Lua Error',
    rpc_error = 'RPC Error',
    echoerr = 'Error',
    wmsg = 'Warning',
    bufwrite = 'Write',
    quickfix = 'Quickfix',
    shell_cmd = 'Shell',
    shell_err = 'Shell Error',
    progress = 'Progress',
}

-- kinds better handled by statusline / cmdline, skip in notify
local SKIP_KIND = {
    search_count = true,
    search_cmd = true,
    completion = true,
    wildlist = true,
    showmode = true,
    empty = true,
}

function M.setup(opts)
    UserConfig = opts or {}
    local notify = require 'notify'
    Bus.register_subscriber(
        'notify',
        { exact = { 'notify' }, prefix = { 'msg.show.' } },
        vim.log.levels.DEBUG,
        function(msg)
            if msg.tag == 'bus' then
                notify(msg.content, msg.level, { title = 'Bus' })
                return false
            end

            -- handle msg.clear
            if msg.tag == 'msg.clear' then
                replace_map = {}
                kind_active = {}
                notify.dismiss { silent = true, pending = true }
                return false
            end

            -- handle notify calls
            if msg.tag == 'notify' then
                -- normal notify message
                notify(msg.content, msg.level, msg.data)
                return false
            end

            -- handle msg.show.*

            local data = msg.data ---@type NvimMsgShowData
            if not data then
                return false
            end

            local kind = data.kind
            if SKIP_KIND[kind] then
                return false
            end

            local content = msg.content
            if not content then
                return false
            end

            ---@type SentMsg|nil
            local prev
            if ALWAYS_REPLACE_CURRENT_KIND[kind] then
                prev = kind_active[kind]
            elseif data.replace_last then
                prev = replace_map[msg.id]
            end

            -- append: grow content in place
            if data.append and prev and prev.content then
                local merged = {}
                vim.list_extend(merged, prev.content)
                vim.list_extend(merged, content)
                content = merged
            end

            local layout = layout_chunks(content)

            local notify_opts = {
                title = KIND_TITLE[kind] or 'Messages',
                replace = prev and prev.rec,
                render = make_render(layout),
                on_close = function()
                    kind_active[kind] = nil
                end,
            }

            local text = table.concat(layout.lines, '\n')
            local record = notify(text, msg.level, notify_opts)

            if ALWAYS_REPLACE_CURRENT_KIND[kind] then
                kind_active[kind] = { content = content, rec = record }
            else
                replace_map[msg.id] = { content = content, rec = record }
            end

            return false
        end
    )
end

return M

--------------------------------------------------------------------------------
-- LSP progress notifications
-- Tracks progress per-client and renders a single aggregated notify
--------------------------------------------------------------------------------

---@type table<number, {token:lsp.ProgressToken, msg:NvimMsgChunk[], done:boolean}[]>
local progress = vim.defaulttable()
local toast = require 'core.ui.toast'

local last_chunks_cache = {}

---@type Timer|nil
local UPDATE_TIMER = nil

-- Spinner glyphs used while progress is active
local spinner =
    { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }

local get_hlid = vim.api.nvim_get_hl_id_by_name

local HLIDS = {
    msg_percentage = get_hlid 'Operator',
    msg_title = get_hlid 'Normal',
    msg_content = get_hlid 'Comment',
}

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

---Return a consistent progress message for a single LSP progress value
---@param value {percentage?: number, title?: string, message?: string, kind: "begin"|"report"|"end"}
---@return NvimMsgChunk[]
local function build_msg(value)
    return {
        {
            0,
            ('%3d%% '):format(
                value.kind == 'end' and 100 or value.percentage or 100
            ),
            HLIDS.msg_percentage,
        }, -- percentage
        {
            0,
            value.title or '',
            HLIDS.msg_title,
        }, -- title
        {
            0,
            value.message and (' %s'):format(value.message) or '',
            HLIDS.msg_content,
        }, -- message
    }
end

---Compute spinner icon based on current time and progress state
---@param client_id integer
---@return string
local function get_icon(client_id)
    if #progress[client_id] == 0 then
        return ' '
    end
    local idx = math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1
    return spinner[idx]
end

---@param client_id integer
---@param client_name string
local function do_render(client_id, client_name)
    local msg = last_chunks_cache[client_id]
    if not msg or #msg == 0 then
        return
    end

    local is_done = #progress[client_id] == 0

    -- direct display, not using the bus at this moment
    toast.notify(msg, {
        id = 'lsp_progress.' .. client_name,
        title = client_name,
        icon = get_icon(client_id),
        relayout = true,
    })

    if is_done and UPDATE_TIMER then
        UPDATE_TIMER:close()
        UPDATE_TIMER = nil
        last_chunks_cache[client_id] = nil
    elseif UPDATE_TIMER then
        UPDATE_TIMER:restart()
    end
end

--------------------------------------------------------------------------------
-- Handler
--------------------------------------------------------------------------------

---Process a single LspProgress event
---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
local function on_progress(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    --[[@as {percentage?: number, title?: string, message?: string, kind: "begin" | "report" | "end"}]]
    local value = ev.data.params.value
    if not client or type(value) ~= 'table' then
        return
    end

    local p = progress[client.id]
    for i = 1, #p + 1 do
        if i == #p + 1 or p[i].token == ev.data.params.token then
            p[i] = {
                token = ev.data.params.token,
                msg = build_msg(value),
                done = value.kind == 'end',
            }
            break
        end
    end

    local msg = {} ---@type NvimMsgChunk[]
    progress[client.id] = vim.tbl_filter(function(v)
        if #msg > 0 then
            table.insert(msg, require 'utils.render'.NEWLINE_CHUNK)
        end
        vim.list_extend(msg, v.msg)
        return not v.done
    end, p)

    if #msg == 0 then
        return
    end
    last_chunks_cache[client.id] = msg

    do_render(client.id, client.name)

    if #progress[client.id] > 0 then
        if not UPDATE_TIMER then
            local Timer = require 'utils.timer'
            UPDATE_TIMER = Timer.new(100, function()
                vim.schedule(function()
                    if client then
                        do_render(client.id, client.name)
                    end
                end)
            end)
            UPDATE_TIMER:start()
        end
    end
end

--------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------

local M = {}

function M.setup()
    vim.api.nvim_create_autocmd('LspProgress', {
        callback = on_progress,
    })

    -- Clean the progress table when Lsp Detach
    vim.api.nvim_create_autocmd('LspDetach', {
        callback = function(ev)
            progress[ev.data.client_id] = nil
        end,
    })
end

return M

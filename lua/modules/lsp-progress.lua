--------------------------------------------------------------------------------
-- LSP progress notifications
-- Tracks progress per-client and renders a single aggregated notify
--------------------------------------------------------------------------------

---@type table<number, {token:lsp.ProgressToken, msg:string, done:boolean}[]>
local progress = vim.defaulttable()
local toast = require 'ui.toast'

-- Spinner glyphs used while progress is active
local spinner =
    { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

---Return a consistent progress message for a single LSP progress value
---@param value {percentage?: number, title?: string, message?: string, kind: "begin"|"report"|"end"}
---@return string
local function build_msg(value)
    return ('[%3d%%] %s%s'):format(
        value.kind == 'end' and 100 or value.percentage or 100,
        value.title or '',
        value.message and (' **%s**'):format(value.message) or ''
    )
end

---Compute spinner icon based on current time and progress state
---@param client_id number
---@return string
local function get_icon(client_id)
    if #progress[client_id] == 0 then
        return ' '
    end
    local idx = math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1
    return spinner[idx]
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

    local msg = {} ---@type string[]
    progress[client.id] = vim.tbl_filter(function(v)
        return table.insert(msg, v.msg) or not v.done
    end, p)

    if #msg == 0 then
        return
    end

    -- direct display, not using the bus at this moment
    toast.notify(table.concat(msg, '\n'), {
        id = 'lsp_progress',
        title = client.name,
        icon = get_icon(client.id),
        relayout = true,
    })
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

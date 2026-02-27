local M = {}

---Send notify
---@param massage string
---@param opts table | nil
function M.info(massage, opts)
    vim.notify(massage, vim.log.levels.INFO, opts)
end

---@param massage string
---@param opts table | nil
function M.warn(massage, opts)
    vim.notify(massage, vim.log.levels.WARN, opts)
end

---@param massage string
---@param opts table | nil
function M.err(massage, opts)
    vim.notify(massage, vim.log.levels.ERROR, opts)
end

---@param massage string
---@param opts table | nil
function M.debug(massage, opts)
    vim.notify(massage, vim.log.levels.DEBUG, opts)
end

---@param massage string
---@param opts table | nil
function M.trace(massage, opts)
    vim.notify(massage, vim.log.levels.TRACE, opts)
end

--- TODO: open file with default utils...?
function M.open() end

---@class LogItem
---@field lvl number
---@field msg string
---@field time number

--- NOTE: LogQueue is logging infrastructure provided for preload stage,
--- before noice/notify is initialized
---
---@class LogQueue
---@field data LogItem[]
---@field info fun(msg: string)
---@field warn fun(msg: string)
---@field error fun(msg: string)
---@field debug fun(msg: string)

local levels = vim.log.levels

---@param title string
---@return LogQueue
function M.make_log_queue(title)
    local instance = {
        title = title,
        data = {},
    }

    return setmetatable(instance, {
        __index = function(self, key)
            local lvl = levels[key:upper()]
            if lvl then
                return function(msg)
                    table.insert(self.data, {
                        lvl = lvl,
                        msg = msg,
                        time = vim.uv.now(),
                    })
                end
            end
            return rawget(self, key)
        end,
    })
end

function M.flush_log_queue(queue)
    if #queue.data == 0 then
        return
    end

    vim.schedule(function()
        for _, item in ipairs(queue.data) do
            vim.notify(item.msg, item.lvl, {
                title = queue.title or 'Preload',
            })
        end
        queue.data = {}
    end)
end

function M.pad(s, width)
    return s .. string.rep(' ', width - #s)
end

local function validate_cmd(v)
    if type(v) == 'table' then
        if vim.fn.executable(v[1]) == 0 then
            return false, v[1] .. ' is not executable'
        end
        return true
    end
    return type(v) == 'function'
end

--- @param config vim.lsp.Config
local function validate_config(config)
    vim.validate('cmd', config.cmd, validate_cmd, 'expected function or table with executable command')
    vim.validate('reuse_client', config.reuse_client, 'function', true)
    vim.validate('filetypes', config.filetypes, 'table', true)
end

--- Returns true if:
--- 1. the config is managed by vim.lsp,
--- 2. it applies to the given buffer, and
--- 3. its config is valid (in particular: its `cmd` isn't broken).
---
--- @param bufnr integer
--- @param config vim.lsp.Config
--- @param logging boolean
local function can_start(bufnr, config, logging)
    assert(config)
    if type(config.filetypes) == 'table' and not vim.tbl_contains(config.filetypes, vim.bo[bufnr].filetype) then
        return false
    end

    local config_ok, err = pcall(validate_config, config)
    if not config_ok then
        if logging then
            M.error(('invalid "%s" config: %s'):format(config.name, err))
        end
        return false
    end

    return true
end

--- @param bufnr integer
--- @param config vim.lsp.Config
local function start_config(bufnr, config)
    return vim.lsp.start(config, {
        bufnr = bufnr,
        reuse_client = config.reuse_client,
        _root_markers = config.root_markers,
    })
end

--- @param bufnr integer
function M.lsp_buf_startup(bufnr)
    local lsp = vim.lsp
    -- Only ever attach to buffers that represent an actual file.
    if vim.bo[bufnr].buftype ~= '' then
        return
    end

    -- Stop any clients that no longer apply to this buffer.
    local clients = lsp.get_clients { bufnr = bufnr, _uninitialized = true }
    for _, client in ipairs(clients) do
        -- Don't index into lsp.config[…] unless is_enabled() is true.
        if
            lsp.is_enabled(client.name)
            -- Check that the client is managed by vim.lsp.config before deciding to detach it!
            and lsp.config[client.name]
            and not can_start(bufnr, lsp.config[client.name], false)
        then
            lsp.buf_detach_client(bufnr, client.id)
        end
    end

    -- Start any clients that apply to this buffer.
    for name in vim.spairs(lsp._enabled_configs) do
        local config = lsp.config[name]
        if config and can_start(bufnr, config, true) then
            M.debug('Started LSP: [' .. name .. ']', { title = 'Info' })

            -- Deepcopy config so changes done in the client
            -- do not propagate back to the enabled configs.
            config = vim.deepcopy(config)

            if type(config.root_dir) == 'function' then
                ---@param root_dir string
                config.root_dir(bufnr, function(root_dir)
                    config.root_dir = root_dir
                    vim.schedule(function()
                        start_config(bufnr, config)
                    end)
                end)
            else
                start_config(bufnr, config)
            end
        end
    end
end

return M

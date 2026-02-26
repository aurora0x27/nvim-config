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

return M

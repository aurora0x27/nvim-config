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

return M

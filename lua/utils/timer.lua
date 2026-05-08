--------------------------------------------------------------------------------
-- Timer wrapper
--------------------------------------------------------------------------------
local M = {}
M.__index = M

---@class Timer
---@field start function
---@field restart function
---@field stop function
---@field close function

---@param ms integer
---@param cb function
function M.new(ms, cb)
  local self = setmetatable({}, M)
  self.ms = ms
  self.cb = cb
  self.handle = vim.uv.new_timer()
  return self
end

function M:start()
  self.handle:start(self.ms, 0, function()
    vim.schedule(self.cb)
  end)
end

function M:stop()
  if self.handle then
    self.handle:stop()
  end
end

function M:restart()
  self:stop()
  self:start()
end

function M:close()
  if self.handle then
    self.handle:stop()
    self.handle:close()
  end
end

return M

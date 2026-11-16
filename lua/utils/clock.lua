--------------------------------------------------------------------------------
-- Timestamp helpers
--
-- A timestamp carries two independent facts: a best-effort wall-clock value
-- for human display, and a monotonic value for identity and ordering. The wall
-- clock is optional because it can be unavailable; the monotonic value always
-- exists. Rendering is total: an unusable wall clock degrades to a placeholder
-- instead of failing the caller.
--------------------------------------------------------------------------------
local M = {}

local uv = vim.uv

---Return a timestamp without ever failing.
---The wall-clock field is absent when it cannot be obtained.
---@return BusTimestamp
function M.safe_gettime()
  local ret = { mono = uv.hrtime() } --[[@as BusTimestamp]]
  local ok, ts = pcall(M.unsafe_gettime)
  if ok then
    ret.real = ts
  end
  return ret
end

---Render a timestamp for display.
---Falls back to a placeholder when the wall clock is unavailable or unusable.
---
---@param ts BusTimestamp
---@param fmt? string
---@return string
function M.render(ts, fmt)
  if type(ts) == 'table' and type(ts.real) == 'number' and ts.real > 0 then
    local ok, ret =
      pcall(os.date, fmt or '%H:%M:%S', math.floor(ts.real / 1000))
    if ok and type(ret) == 'string' then
      return ret
    end
  end
  return '??:??:??'
end

---Return wall-clock time in milliseconds.
---May raise; callers that cannot handle failure should use `safe_gettime`.
---@return number
function M.unsafe_gettime()
  local sec, usec = uv.gettimeofday()
  if not sec then
    error('Cannot get time because `' .. tostring(usec) .. '`')
  end
  return sec * 1000 + usec / 1000
end

return M

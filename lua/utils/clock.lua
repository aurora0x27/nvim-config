--------------------------------------------------------------------------------
-- A clock that won't panic
--
-- Two clocks are exposed together:
--   * `real`: Unix epoch milliseconds, best effort. Both gettimeofday() and
--     os.time() are fallible, so this may be nil.
--   * `mono`: uv.hrtime() nanoseconds, monotonic and infallible. Use it for
--     ordering and durations, never render it as a date.
--
-- The wall clock is anchored once, then advanced with the monotonic delta. A
-- failed calibration is retried periodically, and callers may re-anchor on
-- events such as VimResume (CLOCK_MONOTONIC does not include suspend time).
--------------------------------------------------------------------------------
local M = {}

local uv = vim.uv

-- Retry a failed wall-clock calibration at most this often.
local RETRY_INTERVAL_NS = 5e9

--- Create a clock instance.
---
--- The returned `now` function never throws and always returns the monotonic
--- value; `real` is nil when the wall clock cannot be determined.
---
---@return fun(): number?, number  real (epoch ms or nil), mono (ns)
---@return fun(): boolean          calibrate() best-effort re-anchor
function M.create_clock()
  local wall_anchor
  local mono_anchor = uv.hrtime()
  local last_try = mono_anchor

  ---@return boolean
  local function calibrate()
    local ok, sec, usec = pcall(uv.gettimeofday)
    if ok and type(sec) == 'number' and sec > 0 and type(usec) == 'number' then
      wall_anchor = sec * 1000 + usec / 1000
      mono_anchor = uv.hrtime()
      return true
    end

    local success, timestamp = pcall(os.time)
    -- os.time() reports failure as -1, not nil.
    if success and type(timestamp) == 'number' and timestamp > 0 then
      wall_anchor = timestamp * 1000
      mono_anchor = uv.hrtime()
      return true
    end

    -- Do not keep serving a possibly stale anchor: this may be a failed
    -- re-anchor after suspend. now() retries shortly and renders fallback
    -- (??-??-??-<mono>) until then.
    wall_anchor = nil
    last_try = uv.hrtime()
    return false
  end

  calibrate()

  ---@return number?, number
  local function now()
    local mono = uv.hrtime()

    if not wall_anchor and mono - last_try >= RETRY_INTERVAL_NS then
      last_try = mono
      if calibrate() then
        mono = uv.hrtime()
      end
    end

    if not wall_anchor then
      return nil, mono
    end

    return math.floor(wall_anchor + (mono - mono_anchor) / 1e6), mono
  end

  return now, calibrate
end

--- Render a BusTimestamp. When `real` is unavailable (or os.date() fails),
--- fall back to the monotonic value so the timestamp remains identifiable.
---
---@param ts { real: number?, mono: number }?
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
  return '??-??-??-' .. tostring(type(ts) == 'table' and ts.mono or '?')
end

return M

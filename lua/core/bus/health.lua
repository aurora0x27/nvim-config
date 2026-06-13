local M = {}

function M.check()
  local Bus = require 'core.bus'
  local health = vim.health

  health.start('Bus')

  ------------------------------------------------------------------
  -- Runtime State
  ------------------------------------------------------------------
  if not Bus then
    health.error('Bus not initialzed')
    return
  end

  local Stat = Bus.snapshot()

  if Stat.Ready then
    health.ok('Bus started')
  else
    health.warn('Bus not started')
  end

  if Stat.Busy then
    health.warn('Dispatcher currently busy')
  else
    health.ok('Dispatcher idle')
  end

  health.info(
    string.format(
      'Initialized=%s Ready=%s FlushDepth=%d',
      tostring(Stat.IsInitialized),
      tostring(Stat.Ready),
      Stat.FlushDepth
    )
  )

  ------------------------------------------------------------------
  -- Queue
  ------------------------------------------------------------------
  health.info(string.format('Queue: %d pending messages', #Stat.Queue))

  if Stat.QueueEnd > #Stat.Queue + 1 then
    health.error(
      string.format(
        'QueueEnd=%d exceeds queue length=%d',
        Stat.QueueEnd,
        #Stat.Queue
      )
    )
  end

  ------------------------------------------------------------------
  -- Routing Cache
  ------------------------------------------------------------------
  local route_count = 0

  for _ in pairs(Stat.RouteCache) do
    route_count = route_count + 1
  end

  health.info(string.format('Route cache entries: %d', route_count))

  ------------------------------------------------------------------
  -- Observers
  ------------------------------------------------------------------
  local observer_total = 0
  local observer_enabled = 0

  for _, enabled in pairs(Stat.Observers or {}) do
    observer_total = observer_total + 1

    if enabled then
      observer_enabled = observer_enabled + 1
    end
  end

  if observer_enabled == 0 then
    health.error('No active observer')
  else
    health.ok(string.format('%d active observer(s)', observer_enabled))
  end

  if observer_total > observer_enabled then
    health.warn(
      string.format(
        '%d observer(s) disabled',
        observer_total - observer_enabled
      )
    )
  end

  ------------------------------------------------------------------
  -- Panic History
  ------------------------------------------------------------------
  local panic_count = #(Stat.PanicBuffer or {})

  if panic_count == 0 then
    health.ok('No recorded internal panic')
  else
    health.warn(string.format('%d panic record(s) stored', panic_count))

    local start = math.max(1, panic_count - 10 + 1)

    for i = start, panic_count do
      local rec = Stat.PanicBuffer[i]

      health.info(
        string.format(
          '[%s] %s',
          vim.log.levels[rec.level] or rec.level,
          rec.msg
        )
      )
    end
  end
end

return M

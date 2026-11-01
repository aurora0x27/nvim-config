--------------------------------------------------------------------------------
-- Message Bus -- Tag based message router
--
-- The message bus provides a lightweight event routing layer for the editor
-- runtime. It decouples message producers from consumers by transforming
-- runtime events into tagged, identifiable messages and dispatching them to
-- registered subscribers.
--
-- The bus owns the routing state it needs: a FIFO of pending messages, the
-- cursor of the last dequeued message (LastEmitted, 0 when empty), and the
-- flags that serialize dispatch and draining. Stateful presentation such as
-- rendering, notification display, persistence, or message history remains in
-- independent adapters/backends that subscribe to the bus. This design lets
-- different UI components (toast, progress, notification window, log recorder)
-- consume the same stream without coupling producers to a presentation layer.
--
-- Emission is synchronous when possible:
--   * Ready and not Busy: dispatch immediately, then drain pending messages.
--   * Busy: append to the queue; the active drain will process it.
--   * fast-api context: append and schedule one safe-context drain.
--   * not Ready: append; Bus.start() drains the startup queue.
--
-- Draining is iterative, not recursive. flush_queue processes the pending
-- queue in epochs: messages emitted during one batch are handled in the next
-- epoch. The pending queue is bounded by queue_limit; push() drops new messages
-- when it is full. max_epoch bounds the number of epochs before the queue is
-- dropped; full BusStat/Queue diagnostics on that path are still TODO.
--
-- The commented LogQueue below is kept as a record of the pre-bus startup
-- buffering stage; it is no longer used.
--
-- ```lua
--
-- ---@class LogItem
-- ---@field lvl number
-- ---@field msg string
-- ---@field time number
--
-- ---@class LogQueue
-- ---@field data LogItem[]
-- ---@field info fun(msg: string)
-- ---@field warn fun(msg: string)
-- ---@field error fun(msg: string)
-- ---@field debug fun(msg: string)
--
-- local levels = vim.log.levels
--
-- ---@param title string
-- ---@return LogQueue
-- function M.make_log_queue(title)
--   local instance = {
--     title = title,
--     data = {},
--   }
--
--   return setmetatable(instance, {
--     __index = function(self, key)
--       local lvl = levels[key:upper()]
--       if lvl then
--         return function(msg)
--           table.insert(self.data, {
--             lvl = lvl,
--             msg = msg,
--             time = vim.uv.now(),
--           })
--         end
--       end
--       return rawget(self, key)
--     end,
--   })
-- end
--
-- function M.flush_log_queue(queue)
--   if #queue.data == 0 then
--     return
--   end
--
--   vim.schedule(function()
--     for _, item in ipairs(queue.data) do
--       vim.notify(item.msg, item.lvl, {
--         title = queue.title or 'Preload',
--       })
--     end
--     queue.data = {}
--   end)
-- end
-- ```
--------------------------------------------------------------------------------
local M = {}

---@class BusInitOpt
---@field queue_limit? integer max pending messages (default 2048)
---@field max_epoch?   integer max drain epochs per flush (default 8)

---@class BusSubscriber
---@field id string
---@field full_match table<string, boolean> extact strings match to match interested tags
---@field prefix_match string[]
---@field fuzzy_match string[] fuzzy patterns to match interested tags
---@field min_level vim.log.levels
---@field handler fun(msg: Message): boolean

---@class BusSubscriberInterestedTagDecl
---@field exact?  string[]   O(1) hash lookup
---@field prefix? string[]   O(n) startswith
---@field fuzzy?  string[]   O(n) lua pattern match

---@alias BusSubscriberMessageConsumer fun(msg: Message): boolean

---@class BusSubscriberDecl for user config
---@field id string
---@field interested BusSubscriberInterestedTagDecl
---@field min_level vim.log.levels
---@field handler BusSubscriberMessageConsumer

---@alias BusObserverCb fun(msg: Message)

---@class BusOpt
---@field subscribers? BusSubscriberDecl[]

---@class Message
---@field id        integer        unique message id (stable for replace_last)
---@field tag       string         routing tag e.g. "msg.show.echomsg", "notify"
---@field level     integer
---@field content   any            payload, format defined by tag convention
---@field timestamp number         vim.uv.now()
---@field meta      table          meta flags
---@field data      table?         source-defined metadata, opaque to bus

---@class BusPanicRecord
---@field time      number
---@field level     integer
---@field msg       string

---@type BusInitOpt
local BUS_INIT_OPT_DEFAULT = {
  queue_limit = 2048,
  max_epoch = 8,
}

---@type BusInitOpt
local InitOpt = vim.deepcopy(BUS_INIT_OPT_DEFAULT)

local BUS_OPT_DEFAULT = { handlers = {}, subscribers = {} }

---@type BusOpt
local Opt = vim.deepcopy(BUS_OPT_DEFAULT)

---@class BusStat
---@field IsInitialized  boolean
---@field Ready          boolean cache message when ui not ready
---@field Queue          Message[] fifo message buffer
---@field Busy           boolean is dispatching message?
---@field LastEmitted    integer index of the last dequeued message; 0 when empty
---@field Flushing       boolean drain loop is active
---@field FlushScheduled boolean has scheduled a flush operation
---@field Subscribers    table<string, BusSubscriber>
---@field Observers      table<string, BusObserverCb>
---@field RouteCache     table<string, table<string, boolean>>
---@field PanicBuffer    BusPanicRecord[]

---@class BusStatView readonly view of BusStat, Queue and Route cache
---                   are *not* copied
---@field IsInitialized boolean
---@field Ready         boolean cache message when ui not ready
---@field QueuePending  integer number of messages not yet dequeued
---@field Busy          boolean is dispatching message?
---@field LastEmitted   integer index of the last dequeued message
---@field Flushing      boolean drain loop is active
---@field FlushScheduled boolean
---@field Subscribers   string[]
---@field Observers     string[]
---@field PanicBuffer   BusPanicRecord[]

---@type BusStat
local Stat = {
  IsInitialized = false,
  Ready = false,
  Queue = {},
  Busy = false,
  LastEmitted = 0,
  Flushing = false,
  FlushScheduled = false,
  Subscribers = {},
  Observers = {},
  RouteCache = {},
  PanicBuffer = {},
}

---@type table<string, BusSubscriber>
local Subscribers = Stat.Subscribers

--- Used to boardcast internal logs
---@type table<string, BusObserverCb>
local Observers = Stat.Observers

---@return BusStat
function M.snapshot()
  return vim.deepcopy(Stat)
end

---@return BusStatView
function M.inspect()
  ---@type BusStatView
  local ret = {
    Busy = Stat.Busy,
    Ready = Stat.Ready,
    Flushing = Stat.Flushing,
    FlushScheduled = Stat.FlushScheduled,
    IsInitialized = Stat.IsInitialized,
    Observers = vim.tbl_keys(Stat.Observers),
    Subscribers = vim.tbl_keys(Stat.Subscribers),
    PanicBuffer = vim.deepcopy(Stat.PanicBuffer),
    LastEmitted = Stat.LastEmitted,
    QueuePending = #Stat.Queue - Stat.LastEmitted,
  }
  return ret
end

---@param id string
---@param interested BusSubscriberInterestedTagDecl patterns to match interested tags
---@param min_level vim.log.levels
---@param handler BusSubscriberMessageConsumer
---@return boolean, string?
function M.register_subscriber(id, interested, min_level, handler)
  if Subscribers[id] then
    return false, 'Subscriber `' .. id .. '` already exist'
  end
  local set = {}
  if interested.exact then
    for _, candidate in ipairs(interested.exact) do
      set[candidate] = true
    end
  end
  Subscribers[id] = {
    id = id,
    prefix_match = interested.prefix or {},
    full_match = set,
    fuzzy_match = interested.fuzzy or {},
    min_level = min_level,
    handler = handler,
  }
  return true
end

---@param id string
---@param cb BusObserverCb
function M.register_observer(id, cb)
  if not Observers[id] then
    Observers[id] = cb
  end
end

---@param id string
function M.unsubscribe(id)
  Subscribers[id] = nil
  -- clear cache, since this function is rarely used
  Stat.RouteCache = {}
end

local _id_counter = 0
---@return integer
local function new_id()
  _id_counter = _id_counter + 1
  return _id_counter
end

---@param tag string
---@param level integer
---@param content string|table
---@param data? table
---@param cover_id? integer
---@return Message
local function build_msg(tag, level, content, data, cover_id)
  local id
  if cover_id then
    id = cover_id
  else
    id = new_id()
  end
  ---@type Message
  return {
    id = id,
    tag = tag,
    level = level,
    content = content,
    timestamp = vim.uv.now(),
    data = data,
    meta = {},
  }
end

---@param msg string
---@param lvl vim.log.levels
local function bus_panic(msg, lvl)
  ---@type BusPanicRecord
  local rec = { msg = msg, level = lvl, time = vim.uv.now() }
  table.insert(Stat.PanicBuffer, rec)
end

-- Pipe internal message to observers
---@param msg string
---@param lvl? vim.log.levels
local function bus_log(msg, lvl)
  local built_msg = build_msg('bus', lvl or vim.log.levels.INFO, msg)
  local has_sent = false
  for id, cb in pairs(Observers) do
    local ok, err = pcall(cb, built_msg)
    if not ok then
      bus_panic(
        '[Bus Log] callback `' .. id .. '` panic for `' .. err .. '`',
        vim.log.levels.ERROR
      )
    else
      has_sent = true
    end
  end
  if not has_sent then
    bus_panic(
      '[Bus Log] log message: `' .. msg .. '`',
      lvl or vim.log.levels.WARN
    )
  end
end

---@param tag        string
---@param backend_id string
---@param ret        boolean
local function add_to_cache(tag, backend_id, ret)
  if Stat.RouteCache[tag] then
    Stat.RouteCache[tag][backend_id] = ret
  else
    Stat.RouteCache[tag] = { [backend_id] = ret }
  end
end

---@param backend BusSubscriber
---@param tag string
local function matches(backend, tag)
  -- Try to find in cache
  if Stat.RouteCache[tag] and Stat.RouteCache[tag][backend.id] ~= nil then
    -- Cache hit
    return Stat.RouteCache[tag][backend.id]
  end
  -- Cache miss

  if backend.full_match[tag] then
    add_to_cache(tag, backend.id, true)
    return true
  end

  for _, prefix in ipairs(backend.prefix_match) do
    if vim.startswith(tag, prefix) then
      add_to_cache(tag, backend.id, true)
      return true
    end
  end

  for _, pattern in ipairs(backend.fuzzy_match) do
    if tag:match(pattern) then
      add_to_cache(tag, backend.id, true)
      return true
    end
  end

  add_to_cache(tag, backend.id, false)
  return false
end

-- Request for a deferred flush operation
local function schedule_flush()
  if not Stat.Ready or Stat.FlushScheduled then
    return
  end
  Stat.FlushScheduled = true
  vim.schedule(function()
    Stat.FlushScheduled = false
    M.flush_queue()
  end)
end

local sprintf = string.format

---@param msg Message
local function push(msg)
  if #Stat.Queue - Stat.LastEmitted < InitOpt.queue_limit then
    table.insert(Stat.Queue, msg)
  end
end

---@param msg Message
local function bus_dispatch(msg)
  if vim.in_fast_event() or Stat.Busy then
    push(msg)
    schedule_flush()
    return
  end

  Stat.Busy = true

  for _, backend in pairs(Subscribers) do
    if matches(backend, msg.tag) and msg.level >= backend.min_level then
      -- protected call handler
      if type(backend.handler) == 'function' then
        local ok, should_stop = pcall(backend.handler, msg)
        if not ok then
          bus_log(
            sprintf(
              "[Dispatcher] Handler '%s' panic for: '%s'",
              backend.id,
              should_stop
            ),
            vim.log.levels.ERROR
          )
        elseif should_stop == true then
          break
        end
      end
    end
  end

  Stat.Busy = false
end

local function clear_queue()
  Stat.Queue = {}
  Stat.LastEmitted = 0
end

---@return boolean
local function has_pending()
  return Stat.LastEmitted < #Stat.Queue
end

---@param msg Message
local function safe_dispatch(msg)
  local ok, err = pcall(bus_dispatch, msg)
  if not ok then
    pcall(
      bus_log,
      '[Dispatcher] caused a panic for `' .. err .. '`',
      vim.log.levels.ERROR
    )
  end
  -- NOTE: keep Busy held while notifying observers; release after
  Stat.Busy = false
end

local function loop_drain()
  local epoch = 0
  while has_pending() do
    if epoch >= InitOpt.max_epoch then
      -- TODO: panic, dump bus state
      clear_queue()
      break
    end
    local batch_start = Stat.LastEmitted + 1
    local batch_end = #Stat.Queue
    for i = batch_start, batch_end do
      local msg = Stat.Queue[i]
      safe_dispatch(msg)
      Stat.LastEmitted = Stat.LastEmitted + 1
    end
    epoch = epoch + 1
  end
end

function M.flush_queue()
  if not Stat.Ready then
    return
  end
  if vim.in_fast_event() or Stat.Busy then
    schedule_flush()
    return
  end
  if Stat.Flushing then
    return
  end
  Stat.Flushing = true
  local ok, err = pcall(loop_drain)
  if not ok then
    pcall(
      bus_log,
      sprintf('[Queue Flusher] drain panic: `%s`', err),
      vim.log.levels.ERROR
    )
    schedule_flush()
  end
  Stat.Flushing = false
  if not has_pending() then
    clear_queue()
  end
end

---@param msg Message
---@return integer id
local function emit_impl(msg)
  local id = msg.id
  if vim.in_fast_event() or not Stat.Ready or Stat.Busy then
    push(msg)
    schedule_flush()
    return id
  end
  if Stat.Flushing then
    push(msg)
    return id
  end
  if has_pending() then
    push(msg)
  else
    safe_dispatch(msg)
  end
  if has_pending() then
    M.flush_queue()
  end
  return id
end

M.build_msg = build_msg

--- Duplicate as a new emission identity
--- Add a meta.derived_from field
---@param msg Message
---@param overrides table?
---@return Message
function M.dup(msg, overrides)
  local new = vim.deepcopy(msg)

  new.id = new_id()
  new.timestamp = vim.uv.now()

  new.meta = vim.tbl_extend('force', new.meta or {}, {
    derived_from = msg.id,
  }, overrides or {})
  new.meta.is_emitted = false

  return new
end

--- Build and emit a message to bus
---@param tag string
---@param level integer
---@param content string|table
---@param data? table
---@param cover_id? integer
---@return integer id
function M.emit(tag, level, content, data, cover_id)
  local msg = build_msg(tag, level, content, data, cover_id)
  return emit_impl(msg)
end

--- Emit an existing message
---@param msg Message
---@return integer id
function M.emit_msg(msg)
  return emit_impl(msg)
end

--- Stage2: emit messages in buffer and start routing
---@param opts? BusOpt
function M.start(opts)
  if Stat.Ready then
    bus_log('Should not start bus more than once !', vim.log.levels.WARN)
    return
  end
  ---@type BusOpt
  Opt = vim.tbl_extend('force', Opt, opts or {})
  for _, decl in ipairs(Opt.subscribers) do
    M.register_subscriber(
      decl.id,
      decl.interested,
      decl.min_level,
      decl.handler
    )
  end
  if vim.tbl_count(Observers) == 0 then
    bus_panic('[Bus Init] No observers, start silently', vim.log.levels.WARN)
  end
  Stat.Ready = true
  M.flush_queue()
end

--- Stage1: Initialize bus and store messages in a message queue
---@param opts BusInitOpt
function M.init(opts)
  if Stat.IsInitialized then
    return
  end
  InitOpt = vim.tbl_extend('force', InitOpt, opts or {})
  _G.Bus = M
  Stat.IsInitialized = true
end

return M

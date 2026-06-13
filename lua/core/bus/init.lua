--------------------------------------------------------------------------------
-- Message Bus -- Tag based message router
--------------------------------------------------------------------------------
local M = {}

---@class BusInitOpt
---@field cache_max? integer

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
  cache_max = 2048,
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
---@field QueueEnd       integer end(head) of message, point to the message to emit
---@field FlushDepth     integer
---@field Subscribers    table<string, BusSubscriber>
---@field Observers      table<string, BusObserverCb>
---@field RouteCache     table<string, table<string, boolean>>
---@field PanicBuffer    BusPanicRecord[]

---@class BusStatView readonly view of BusStat, Queue and Route cache are not copied
---@field IsInitialized boolean
---@field Ready         boolean cache message when ui not ready
---@field QueueCapacity integer
---@field Busy          boolean is dispatching message?
---@field QueueEnd      integer end(head) of message, point to the message to emit
---@field FlushDepth    integer
---@field Subscribers   string[]
---@field Observers     string[]
---@field PanicBuffer   BusPanicRecord[]

---@type BusStat
local Stat = {
  IsInitialized = false,
  Ready = false,
  Queue = {},
  Busy = false,
  QueueEnd = 1,
  FlushDepth = 0,
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
    FlushDepth = Stat.FlushDepth,
    IsInitialized = Stat.IsInitialized,
    Observers = vim.tbl_keys(Stat.Observers),
    Subscribers = vim.tbl_keys(Stat.Subscribers),
    PanicBuffer = vim.deepcopy(Stat.PanicBuffer),
    QueueEnd = Stat.QueueEnd,
    QueueCapacity = #Stat.Queue - Stat.QueueEnd,
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

---@param msg Message
local function bus_dispatch(msg)
  if Stat.Busy then
    if #Stat.Queue < InitOpt.cache_max then
      table.insert(Stat.Queue, msg)
    end
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
            string.format(
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

local FLUSH_MAX_DEPTH = 4

local function clear_queue()
  Stat.Queue = {}
  Stat.QueueEnd = 1
end

function M.flush_queue()
  if not Stat.Ready or Stat.Busy then
    vim.schedule(M.flush_queue)
    return
  end
  if Stat.FlushDepth >= FLUSH_MAX_DEPTH then
    -- force empty queue
    bus_log(
      string.format(
        '[Queue Flusher] flush_queue exceeded max depth (%d), queue dropped (%d msgs)',
        FLUSH_MAX_DEPTH,
        #Stat.Queue
      ),
      vim.log.levels.ERROR
    )
    clear_queue()
    return
  end

  -- snapshot current batch
  local batch_start = Stat.QueueEnd
  local batch_end = #Stat.Queue
  if batch_start > batch_end then
    -- all clear
    clear_queue()
    return
  end

  -- mark current depth
  Stat.FlushDepth = Stat.FlushDepth + 1

  for i = batch_start, batch_end do
    local msg = Stat.Queue[i]
    Stat.QueueEnd = i + 1
    local ok, err = pcall(bus_dispatch, msg)
    if not ok then
      -- release lock
      Stat.Busy = false
      bus_log(
        '[Queue Flusher] dispatcher panic for `' .. err .. '`',
        vim.log.levels.ERROR
      )
    end
  end

  if #Stat.Queue > batch_end then
    M.flush_queue()
  else
    clear_queue()
  end

  -- unwind depth
  Stat.FlushDepth = Stat.FlushDepth - 1
end

---@param msg Message
---@return integer id
local function emit_impl(msg)
  local id = msg.id
  if not Stat.Ready or Stat.Busy then
    -- push when ui not ready or busy
    if #Stat.Queue < InitOpt.cache_max then
      table.insert(Stat.Queue, msg)
    end
    return id
  end
  -- dispatch
  local ok, err = pcall(bus_dispatch, msg)
  if not ok then
    -- unlock dispatcher avoid locked forever
    Stat.Busy = false
    bus_log(
      '[Emitter] dispatcher panic for `' .. err .. '`',
      vim.log.levels.ERROR
    )
  end
  if Stat.Ready and #Stat.Queue > 0 then
    vim.schedule(M.flush_queue)
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

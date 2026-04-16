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

---@class BusOpt
---@field subscribers? BusSubscriberDecl[]
---@field bus_backend string assign a subscriber to handle bus internal log

---@class Message
---@field id        integer        unique message id (stable for replace_last)
---@field tag       string         routing tag e.g. "msg.show.echomsg", "notify"
---@field level     integer
---@field content   any            payload, format defined by tag convention
---@field timestamp number         vim.uv.now()
---@field data      table?         source-defined metadata, opaque to bus

---@type BusInitOpt
local BUS_INIT_OPT_DEFAULT = {
    cache_max = 2048,
}

---@type BusInitOpt
local InitOpt = vim.deepcopy(BUS_INIT_OPT_DEFAULT)

local BUS_OPT_DEFAULT = { handlers = {}, subscribers = {} }

---@type BusOpt
local Opt = vim.deepcopy(BUS_OPT_DEFAULT)

---@type BusSubscriber[]
local Subscribers = {}

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
    for _, candidate in ipairs(interested.exact) do
        set[candidate] = true
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
function M.unsubscribe(id)
    Subscribers[id] = nil
end

---@class BusStat
---@field IsInitialized boolean
---@field Ready boolean cache message when ui not ready
---@field Queue Message[] fifo message buffer
---@field Busy boolean is dispatching message?
---@field queue_end integer end(head) of message, point to the message to emit
---@field flush_depth integer

---@type BusStat
local Stat = {
    IsInitialized = false,
    Ready = false,
    Queue = {},
    Busy = false,
    queue_end = 1,
    flush_depth = 0,
}

local _id_counter = 0

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
        _id_counter = (_id_counter + 1) % 0x7FFFFFFF
        id = _id_counter
    end
    ---@type Message
    return {
        id = id,
        tag = tag,
        level = level,
        content = content,
        timestamp = vim.uv.now(),
        data = data,
    }
end

-- Pipe internal message to specified subscriber
---@param msg string
---@param lvl? vim.log.levels
local function _bus_log(msg, lvl)
    local built_msg = build_msg('bus', lvl or vim.log.levels.INFO, msg)
    Subscribers[Opt.bus_backend].handler(built_msg)
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
        if msg.level < backend.min_level then
            goto continue
        end

        local match_pattern = false
        if backend.full_match[msg.tag] then
            match_pattern = true
        else
            for _, prefix in ipairs(backend.prefix_match) do
                if vim.startswith(msg.tag, prefix) then
                    match_pattern = true
                    goto finish_matching
                end
            end
            for _, pattern in ipairs(backend.fuzzy_match) do
                if msg.tag:match(pattern) then
                    match_pattern = true
                    goto finish_matching
                end
            end
        end
        ::finish_matching::
        if not match_pattern then
            goto continue
        end

        -- protected call handler
        if type(backend.handler) == 'function' then
            local ok, should_stop = pcall(backend.handler, msg)
            if not ok then
                _bus_log(
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

        ::continue::
    end
    Stat.Busy = false
end

local FLUSH_MAX_DEPTH = 4

local function clear_queue()
    Stat.Queue = {}
    Stat.queue_end = 1
end

function M.flush_queue()
    if not Stat.Ready or Stat.Busy then
        vim.schedule(M.flush_queue)
        return
    end
    if Stat.flush_depth >= FLUSH_MAX_DEPTH then
        -- force empty queue
        _bus_log(
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
    local batch_start = Stat.queue_end
    local batch_end = #Stat.Queue
    if batch_start > batch_end then
        -- all clear
        clear_queue()
        return
    end

    -- mark current depth
    Stat.flush_depth = Stat.flush_depth + 1

    for i = batch_start, batch_end do
        local msg = Stat.Queue[i]
        Stat.queue_end = i + 1
        local ok, err = pcall(bus_dispatch, msg)
        if not ok then
            -- release lock
            Stat.Busy = false
            _bus_log(
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
    Stat.flush_depth = Stat.flush_depth - 1
end

--- Emit a message to bus
---@param tag string
---@param level integer
---@param content string|table
---@param data? table
---@param cover_id? integer
---@return integer id
function M.emit(tag, level, content, data, cover_id)
    local msg = build_msg(tag, level, content, data, cover_id)
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
        _bus_log(
            '[Emiter] dispatcher panic for `' .. err .. '`',
            vim.log.levels.ERROR
        )
    end
    if Stat.Ready and #Stat.Queue > 0 then
        vim.schedule(M.flush_queue)
    end
    return id
end

--- Stage2: emit messages in buffer and start routing
---@param opts BusOpt
function M.start(opts)
    if Stat.Ready then
        _bus_log('Should not start bus more than once !', vim.log.levels.WARN)
        return
    end
    ---@type BusOpt
    Opt = vim.tbl_extend('force', Opt, opts or {})
    for _, decl in ipairs(Opt.subscribers) do
        M.register_subscriber(unpack(decl))
    end
    assert(type(Opt.bus_backend) == 'string' and Subscribers[Opt.bus_backend])
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
end

return M

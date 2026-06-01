--------------------------------------------------------------------------------
-- Type hints
--------------------------------------------------------------------------------

---@alias DetachPolicy
---| 'destroy'  vim native, destroy window
---| 'replace' similar to snacks.bufdelete, replace with other buffers
---| 'idle'    create an empty buffer as placeholder

---@class TabMeta
---@field name? string
---@field attached_buffers integer[]

---@alias BufTypePolicy
---| 'managed'   -- bpm managed, can be collected and vacuumed by bpm
---| 'external'  -- not managed by bpm module, has its own life cycle,
---                 leak on detach
---| 'ephemeral' -- short-lived buffer types, destroy on detach

---@class BufferPoolManagerOptions
---@field buftype_policy? table<string, BufTypePolicy>
---@field default_buftype_policy BufTypePolicy

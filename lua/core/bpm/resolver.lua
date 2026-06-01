--------------------------------------------------------------------------------
-- Resolve names for buffer
--------------------------------------------------------------------------------
local M = {}

---@class TrieNode
---@field children table<string, TrieNode>
---@field refs    integer

---@class SuffixTrie
---
---@private
---@field sep         string
---@field root        TrieNode
---@field unique_set  table<string, string[]>
---@field normalizer? fun(s: string): string
local SuffixTrie = {}

SuffixTrie.__index = SuffixTrie

---@return TrieNode
local function make_node()
  return { children = {}, refs = 0 }
end

---@param path string
---@param sep string
local function split_path(path, sep)
  local parts = vim.split(path, sep, { plain = true })
  if parts[1] == '' then
    table.remove(parts, 1)
  end
  return parts
end

---@param s string
---@return boolean
function SuffixTrie:put(s)
  if self.normalizer then
    s = self.normalizer(s)
  end

  --- filter empty buffer, they won't be calculated
  if s == '' then
    return false
  end

  if self.unique_set[s] then
    -- avoid multi insetions
    return false
  end

  local parts = split_path(s, self.sep)

  self.unique_set[s] = parts

  local i = #parts
  local curr = self.root ---@type TrieNode
  while i >= 1 do
    local seg = parts[i]
    if not curr.children[seg] then
      curr.children[seg] = make_node()
    end
    curr = curr.children[seg]
    curr.refs = curr.refs + 1
    i = i - 1
  end

  return true
end

---@param root     TrieNode
---@param segments string[]
---@param start    integer
local function remove_impl(root, segments, start)
  if start < 1 then
    return
  end

  local seg = segments[start]
  local child = root.children[seg]

  if not child then
    return
  end

  child.refs = child.refs - 1

  if child.refs == 0 then
    root.children[seg] = nil
    return
  end

  remove_impl(child, segments, start - 1)
end

---@param s string
---@return boolean
function SuffixTrie:remove(s)
  if self.normalizer then
    s = self.normalizer(s)
  end

  --- filter empty buffer, they won't be calculated
  if s == '' then
    return false
  end

  if not self.unique_set[s] then
    -- not exists
    return false
  end

  local parts = self.unique_set[s]

  self.unique_set[s] = nil

  remove_impl(self.root, parts, #parts)

  return true
end

---@param s string
---@return string|nil
function SuffixTrie:resolve(s)
  if self.normalizer then
    s = self.normalizer(s)
  end

  local parts = self.unique_set[s]
  if not parts then
    return nil
  end

  local i = #parts
  local curr = self.root
  while i >= 1 do
    local seg = parts[i]
    local child = curr.children[seg]
    if not child then
      return nil -- not expected to reach here, unique_set not filtered this.
    end
    if child.refs == 1 then
      -- found!
      return table.concat(parts, self.sep, i, #parts)
    end
    curr = child
    i = i - 1
  end
end

---@param sep string
---@param normalizer? fun(s: string): string
---@return SuffixTrie
function SuffixTrie.new(sep, normalizer)
  ---@type SuffixTrie
  local obj = {
    sep = sep,
    normalizer = normalizer,
    root = make_node(),
    unique_set = {},
  }
  setmetatable(obj, SuffixTrie)
  return obj
end

M.SuffixTrie = SuffixTrie

return M

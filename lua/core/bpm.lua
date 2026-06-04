--------------------------------------------------------------------------------
-- BufferPoolManager -- calculate buffer to display per tab
--------------------------------------------------------------------------------
local M = {}
local LOG_TITLE = 'BufferPoolManager'

---@alias DetachPolicy
---| 'destroy'  vim native, destroy window
---| 'replace' similar to snacks.bufdelete, replace with other buffers
---| 'idle'    create an empty buffer as placeholder

---@class TabMeta
---@field name? string
---@field attached_buffers integer[]

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
  if path:sub(1, #sep) == sep then
    path = path:sub(#sep + 1)
  end
  return vim.split(path, sep, { plain = true })
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

--- BufferPoolManager Global State
local State = {
  ---@type table<integer, TabMeta>
  tabs = {},
}

local function is_valid(buf_num)
  if not buf_num or buf_num < 1 then
    return false
  end
  local exists = vim.api.nvim_buf_is_valid(buf_num)
  return exists and vim.bo[buf_num].buflisted
end

--- Zero copy return listed tab
---@param tab? integer
---@return integer[]
local function get_listed_bufs(tab)
  local curr = vim.api.nvim_get_current_tabpage()
  tab = tab or curr

  local buf_nums
  if tab == 0 or tab == curr then
    buf_nums = vim.api.nvim_list_bufs()
    local ids = {}
    for _, buf in ipairs(buf_nums) do
      if is_valid(buf) then
        ids[#ids + 1] = buf
      end
    end
    return ids
  else
    local meta = State.tabs[tab]
    return meta and meta.attached_buffers or {}
  end
end

local init_trie = function()
  return SuffixTrie.new(package.config:sub(1, 1), vim.fs.normalize)
end

local BufNameCache = {
  trie = nil,
  dirty = true,
  names = {},
}

-- Rebuild trie
---@return SuffixTrie
local function ensure_cache()
  if BufNameCache.dirty or not BufNameCache.trie then
    BufNameCache.trie = init_trie()
    BufNameCache.names = {}
    for _, tabnr in ipairs(vim.api.nvim_list_tabpages()) do
      for _, bufnr in ipairs(get_listed_bufs(tabnr)) do
        if vim.api.nvim_buf_is_valid(bufnr) then
          local path = vim.api.nvim_buf_get_name(bufnr)
          if path ~= '' then
            BufNameCache.trie:put(path)
          end
        end
      end
    end
    BufNameCache.dirty = false
  end
  return BufNameCache.trie
end

function BufNameCache.expire()
  BufNameCache.dirty = true
end

---@param bufnr integer
---@return string
function BufNameCache.resolve(bufnr)
  local trie = ensure_cache()
  local name = BufNameCache.names[bufnr]
  if name then
    return name
  else
    local path = vim.api.nvim_buf_get_name(bufnr)
    local ret = ''
    if path ~= '' then
      ret = trie:resolve(path) or vim.fn.fnamemodify(path, ':t')
    end
    BufNameCache.names[bufnr] = ret
    return ret
  end
end

---@param value boolean
---@param tabid? integer
local function mark_buflisted(value, tabid)
  tabid = tabid or vim.api.nvim_get_current_tabpage()

  local meta = State.tabs[tabid]
  if meta then
    for _, buf in ipairs(meta.attached_buffers) do
      if vim.api.nvim_buf_is_valid(buf) then
        vim.bo[buf].buflisted = value
      end
    end
  end
end

---@param tab integer
---@param exclude integer
---@return integer?
local function find_replacement(tab, exclude)
  local bufs = get_listed_bufs(tab)

  for _, buf in ipairs(bufs) do
    if buf ~= exclude and vim.api.nvim_buf_is_valid(buf) then
      return buf
    end
  end

  return nil
end

---@return integer
local function create_idle_buffer()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  return buf
end

---@param buf integer
---@param tab integer
---@return integer[]
local function find_tab_wins(buf, tab)
  local ret = {}

  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.api.nvim_win_is_valid(win) then
      if vim.api.nvim_win_get_tabpage(win) == tab then
        table.insert(ret, win)
      end
    end
  end

  return ret
end

---@param list integer[]
---@param value integer
local function remove_value(list, value)
  for i, v in ipairs(list) do
    if v == value then
      table.remove(list, i)
      return
    end
  end
end

---@param buf integer
---@param tab integer
---@param policy DetachPolicy
local function handle_windows(buf, tab, policy)
  local wins = find_tab_wins(buf, tab)

  -- Window handling
  if policy == 'destroy' then
    for _, win in ipairs(wins) do
      if vim.api.nvim_win_is_valid(win) then
        pcall(vim.api.nvim_win_close, win, false)
      end
    end
  elseif policy == 'idle' then
    local idle = create_idle_buffer()

    for _, win in ipairs(wins) do
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_set_buf(win, idle)
      end
    end
  else -- replace
    local replacement = find_replacement(tab, buf)

    if not replacement then
      replacement = create_idle_buffer()
    end

    for _, win in ipairs(wins) do
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_set_buf(win, replacement)
      end
    end
  end
end

--- Detach a buffer from a tab
---@param buf?  integer
---@param tab?  integer
---@param policy? DetachPolicy
function M.detach(buf, tab, policy)
  if not buf or buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  tab = tab or vim.api.nvim_get_current_tabpage()
  policy = policy or 'replace'

  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  if vim.bo[buf].modifiable and vim.bo[buf].modified then
    vim.notify(
      'Cannot detach unsaved buffer !',
      vim.log.levels.ERROR,
      { title = LOG_TITLE }
    )
    return
  end

  local tabmeta = State.tabs[tab]
  handle_windows(buf, tab, policy)
  if tabmeta then
    remove_value(tabmeta.attached_buffers, buf)
  end
  vim.bo[buf].buflisted = false
  BufNameCache.expire()
end

--- Close a buffer, detach from all tabs
---@param buf?  integer
---@param policy? DetachPolicy
function M.evict(buf, policy)
  if not buf or buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  policy = policy or 'replace'
  for _, tab in ipairs(vim.tbl_keys(State.tabs)) do
    M.detach(buf, tab, policy)
  end
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

--- Get an array of buffer handles of a tab
---@param tab? integer
---@return integer[]
function M.get_attached_buf(tab)
  local curr = vim.api.nvim_get_current_tabpage()
  tab = tab or curr
  if tab == 0 then
    return vim.list_slice(get_listed_bufs())
  end
  return vim.list_slice(get_listed_bufs(tab))
end

--- Resolve unique buffer name
---@param bufnr integer
---@return string
function M.resolve_bufname(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return '[Invalid]'
  end
  return BufNameCache.resolve(bufnr)
end

--- Get resolved tabname
---@param tabid integer
---@return string
function M.resolve_tabname(tabid)
  local meta = State.tabs[tabid]
  if meta then
    return meta.name or string.format('%d', tabid)
  end
  return string.format('%d', tabid)
end

--- Rename a tab
---@param tabid integer
---@param new_name string
function M.rename_tab(tabid, new_name)
  local meta = State.tabs[tabid]
  if not meta then
    meta = { attached_buffers = get_listed_bufs() }
    State.tabs[tabid] = meta
  end
  meta.name = new_name
  vim.cmd [[ redrawtabline ]]
end

local function on_tab_leave()
  local listed = get_listed_bufs()
  local tab = vim.api.nvim_get_current_tabpage()
  local meta = State.tabs[tab]
  if not meta then
    meta = { attached_buffers = {} }
    State.tabs[tab] = meta
  end
  meta.attached_buffers = listed
  mark_buflisted(false)
end

---@class BufferPoolManagerDumpedState
---@field tabs {bufs: integer[], name:string?}[] -- store the index of file in array `bufs`
---@field bufs string[] -- store paths

-- HACK: recover renamed buffer by sequence, may mismatch
-- BufferPool persistence is ordinal-based.
--
-- The Nth serialized tab state is restored into the Nth runtime tabpage
-- after session restoration.
--
-- Tabpages are treated as ordered task threads rather than stable entities.

--- Dump current state to json
---@return string
function M.to_json()
  --- refresh state
  on_tab_leave()
  mark_buflisted(true)

  ---@type BufferPoolManagerDumpedState
  local to_dump = {
    tabs = {},
    bufs = {},
  }

  local tabs = vim.api.nvim_list_tabpages()

  -- bufnr -> idx
  local bufnr_index = {}

  -- 1. build bufnr index
  for _, tab in ipairs(tabs) do
    local meta = State.tabs[tab]
    if meta then
      for _, bufnr in ipairs(meta.attached_buffers) do
        if
          not bufnr_index[bufnr]
          and vim.api.nvim_buf_is_valid(bufnr)
          and vim.bo[bufnr].buftype == ''
        then
          local name = vim.api.nvim_buf_get_name(bufnr)
          if name ~= '' then
            table.insert(to_dump.bufs, name)
            local idx = #to_dump.bufs
            bufnr_index[bufnr] = idx
          end
        end
      end
    end
  end

  -- 2. fill the table
  for _, tab in ipairs(tabs) do
    local meta = State.tabs[tab]
    if meta then
      local meta_to_dump = {
        name = meta.name,
        bufs = {},
      }

      for _, bufnr in ipairs(meta.attached_buffers) do
        local idx = bufnr_index[bufnr]
        if idx then
          table.insert(meta_to_dump.bufs, idx)
        end
      end

      table.insert(to_dump.tabs, meta_to_dump)
    end
  end

  return vim.json.encode(to_dump)
end

--- Restore a previously dumped BPM state.
---
--- Current BPM graph is replaced by the serialized state.
---
--- Buffers already existing in Neovim are reused when possible.
--- Missing buffers are loaded lazily via bufadd().
---
--- This function reconstructs State.tabs
--- from the serialized snapshot.
---@param data string
function M.from_json(data)
  ---@type BufferPoolManagerDumpedState
  local init = {
    tabs = {},
    bufs = {},
  }

  local ok, ret = pcall(vim.json.decode, data)

  if not ok then
    vim.notify(
      'Cannot decode recover data because\n' .. ret,
      vim.log.levels.ERROR,
      { title = LOG_TITLE }
    )
    return
  end

  ---@type BufferPoolManagerDumpedState
  local dumped = vim.tbl_deep_extend('force', init, ret)

  --- path -> bufnr
  local path_index = {}

  local curr_bufs = vim.api.nvim_list_bufs()
  for _, bufnr in ipairs(curr_bufs) do
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path ~= '' then
      path_index[path] = bufnr
    end
  end

  --- Complete index
  for _, path in ipairs(dumped.bufs) do
    if not path_index[path] then
      local bufnr = vim.fn.bufadd(path)
      if bufnr > 0 then
        vim.fn.bufload(bufnr)
        -- Manually trigger autocmds
        vim.api.nvim_buf_call(bufnr, function()
          vim.api.nvim_exec_autocmds('BufReadPre', { buf = bufnr })
          vim.api.nvim_exec_autocmds('BufRead', { buf = bufnr })
          vim.api.nvim_exec_autocmds('BufReadPost', { buf = bufnr })
          vim.api.nvim_exec_autocmds('FileType', { buf = bufnr })
        end)
        path_index[path] = bufnr
      end
    end
  end

  local bufs = dumped.bufs
  local tabs = dumped.tabs

  local curr_tabs = vim.api.nvim_list_tabpages()
  for i, tabid in ipairs(curr_tabs) do
    local dumped_meta = tabs[i]
    if dumped_meta then
      ---@type TabMeta
      local meta = {
        attached_buffers = {},
        name = dumped_meta.name,
      }

      for _, idx in ipairs(dumped_meta.bufs) do
        local path = bufs[idx]
        if path and path ~= '' then
          local bufnr = path_index[path]
          if bufnr then
            if not vim.tbl_contains(meta.attached_buffers, bufnr) then
              table.insert(meta.attached_buffers, bufnr)
            end
          else
            vim.notify(
              '`' .. path .. '`not in path index!',
              vim.log.levels.WARN,
              { title = LOG_TITLE }
            )
          end
        end
      end
      State.tabs[tabid] = meta
    end
  end
  BufNameCache.expire()
end

local function install_autocmds()
  local Aug = vim.api.nvim_create_augroup('BufferPoolManager', { clear = true })

  ------------------------------------------------------------------------------
  -- Cleanup closed tabs
  ------------------------------------------------------------------------------

  vim.api.nvim_create_autocmd('TabClosedPre', {
    group = Aug,
    callback = function()
      local to_close = vim.api.nvim_get_current_tabpage()
      -- HACK: Skip the TabLeave event
      -- TabClosed only provides tab number, not tab handle.
      -- Capture handle in TabClosedPre and remove state after close.
      vim.schedule(function()
        State.tabs[to_close] = nil
        BufNameCache.expire()
      end)
    end,
  })

  ------------------------------------------------------------------------------
  -- Recompute masking and sync new buffers
  ------------------------------------------------------------------------------

  vim.api.nvim_create_autocmd('TabLeave', {
    group = Aug,
    callback = on_tab_leave,
  })

  vim.api.nvim_create_autocmd('TabEnter', {
    group = Aug,
    callback = function()
      mark_buflisted(true)
    end,
  })

  vim.api.nvim_create_autocmd('TabNewEntered', {
    group = Aug,
    callback = function()
      local tab = vim.api.nvim_get_current_tabpage()
      State.tabs[tab] = { attached_buffers = {} }
    end,
  })

  ------------------------------------------------------------------------------
  -- BufNameCache expire
  ------------------------------------------------------------------------------
  vim.api.nvim_create_autocmd({ 'BufAdd', 'BufWipeout', 'BufFilePost' }, {
    group = Aug,
    callback = function(args)
      local buf = args.buf
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end

        if vim.bo[buf].buflisted then
          BufNameCache.expire()
        end
      end)
    end,
  })
end

function M.debug_dump()
  local chunks = {}
  ---@param str string
  ---@param hl? string
  local function append(str, hl)
    table.insert(chunks, { str, hl or 'Normal' })
  end

  -- Tabs
  append('Tabs:\n', 'Title')
  for tab, meta in pairs(State.tabs) do
    local tabname = M.resolve_tabname(tab)
    append(string.format('  tab %-3d ', tab), 'Number')
    append(tabname .. '\n', 'Title')

    for _, bufnr in ipairs(meta.attached_buffers) do
      local modified = vim.bo[bufnr].modified
      append(string.format('    %-3d ', bufnr), 'Number')
      append(
        M.resolve_bufname(bufnr),
        modified and 'DiagnosticWarn' or 'Directory'
      )
      append(modified and ' [+]\n' or '\n', 'DiagnosticWarn')
    end

    if #meta.attached_buffers == 0 then
      append('    (empty)\n', 'Comment')
    end
  end
  vim.api.nvim_echo(chunks, false, {})
end

local function install_usercmds()
  vim.api.nvim_create_user_command('BpmDumpState', M.debug_dump, {})

  vim.api.nvim_create_user_command('BpmRenameTab', function(opts)
    local name = opts.args
    if name == '' then
      vim.notify(
        'Usage: BpmRenameTab <name>',
        vim.log.levels.WARN,
        { title = LOG_TITLE }
      )
      return
    end
    M.rename_tab(vim.api.nvim_get_current_tabpage(), name)
  end, { nargs = 1, desc = 'Rename the current tab' })

  vim.api.nvim_create_user_command('BpmEvict', function(args)
    local fargs = args.fargs
    local policy = 'replace'
    local bufnrs = {}

    local first = fargs[1]
    local policy_set = { replace = true, idle = true, destroy = true }

    local start = 1
    if first and policy_set[first] then
      policy = first
      start = 2
    end

    for i = start, #fargs do
      local n = tonumber(fargs[i])
      if n then
        table.insert(bufnrs, n)
      else
        vim.notify(
          'Invalid bufnr: ' .. fargs[i],
          vim.log.levels.ERROR,
          { title = LOG_TITLE }
        )
      end
    end

    if #bufnrs == 0 then
      bufnrs = { vim.api.nvim_get_current_buf() }
    end

    for _, bufnr in ipairs(bufnrs) do
      M.evict(bufnr, policy)
    end
  end, {
    nargs = '*',
    complete = function(_, cmdline, _)
      local args = vim.split(cmdline, '%s+')
      if #args == 2 then
        return { 'replace', 'idle', 'destroy' }
      end
      return vim.tbl_map(tostring, M.get_attached_buf())
    end,
    desc = 'Evict buffer(s) all tabs and delete permanently. Usage: BpmEvict [policy] [bufnr...]',
  })

  vim.api.nvim_create_user_command('BpmDetach', function(args)
    local fargs = args.fargs
    local policy = 'replace'
    local bufnrs = {}

    local first = fargs[1]
    local policy_set = { replace = true, idle = true, destroy = 1 }

    local start = 1
    if first and policy_set[first] then
      policy = first
      start = 2
    end

    for i = start, #fargs do
      local n = tonumber(fargs[i])
      if n then
        table.insert(bufnrs, n)
      else
        vim.notify(
          'Invalid bufnr: ' .. fargs[i],
          vim.log.levels.ERROR,
          { title = LOG_TITLE }
        )
      end
    end

    if #bufnrs == 0 then
      bufnrs = { vim.api.nvim_get_current_buf() }
    end

    local tab = vim.api.nvim_get_current_tabpage()
    for _, bufnr in ipairs(bufnrs) do
      M.detach(bufnr, tab, policy)
    end
  end, {
    nargs = '*',
    complete = function(_, cmdline, _)
      local args = vim.split(cmdline, '%s+')
      if #args == 2 then
        return { 'replace', 'idle', 'destroy' }
      end
      return vim.tbl_map(tostring, M.get_attached_buf())
    end,
    desc = 'Detach buffer(s) from the current tab. Usage: BpmDetach [policy] [bufnr...]',
  })

  vim.api.nvim_create_user_command('BpmListTab', function()
    local tab = vim.api.nvim_get_current_tabpage()
    local bufs = M.get_attached_buf(tab)
    local lines = {}
    for _, bufnr in ipairs(bufs) do
      local name = M.resolve_bufname(bufnr)
      local modified = vim.bo[bufnr].modified and ' [+]' or ''
      table.insert(lines, ('%d: %s%s'):format(bufnr, name, modified))
    end
    if #lines == 0 then
      lines = { '(empty)' }
    end
    vim.api.nvim_echo(
      vim.tbl_map(function(l)
        return { l .. '\n', 'Normal' }
      end, lines),
      true,
      {}
    )
  end, { desc = 'List buffers attached to the current tab' })

  vim.api.nvim_create_user_command('BpmBufName', function(args)
    local bufnr = args.count > 0 and args.count
      or vim.api.nvim_get_current_buf()
    local name = M.resolve_bufname(bufnr)
    vim.api.nvim_echo({ { name, 'Normal' } }, false, {})
  end, {
    count = true,
    desc = 'Show resolved name of a buffer. Usage: 42BpmBufName',
  })
end

function M.setup()
  install_autocmds()
  install_usercmds()
end

return M

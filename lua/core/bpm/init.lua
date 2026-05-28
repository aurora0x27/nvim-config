--------------------------------------------------------------------------------
-- BufferPoolManager -- calculate buffer to display per tab
--------------------------------------------------------------------------------
local M = {}
local LOG_TITLE = 'BufferPoolManager'
local Resolver = require 'core.bpm.resolver'

---@alias DetachPolicy
---| 'destroy'  vim native, destroy window
---| 'replace' similar to snacks.bufdelete, replace with other buffers
---| 'idle'    create an empty buffer as placeholder

---@class TabMeta
---@field name? string
---@field attached_buffers integer[]

---@class BufMeta
---@field attached_tabs integer[]

--- BufferPoolManager Global State
local State = {
  ---@type table<integer, TabMeta>
  tabs = {},

  ---@type table<integer, BufMeta>
  bufs = {},
}

--- Resolved unique name cache invalid when buffer add or detach
local BufNameCache = {}

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
local function refresh_projection(tab)
  for _, bufnr in ipairs(vim.tbl_keys(State.bufs)) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.bo[bufnr].buflisted = false
    end
  end

  local meta = State.tabs[tab]

  if meta then
    for _, buf in ipairs(meta.attached_buffers) do
      if vim.api.nvim_buf_is_valid(buf) then
        vim.bo[buf].buflisted = true
      end
    end
  end
end

---@param tab integer
---@param exclude integer
---@return integer?
local function find_replacement(tab, exclude)
  local meta = State.tabs[tab]
  if not meta then
    return nil
  end

  for _, buf in ipairs(meta.attached_buffers) do
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

--- Attach buffer to a tab
---@param buf integer
---@param tab integer
function M.attach(buf, tab)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  -- skip special buffers
  if vim.bo[buf].buftype ~= '' then
    return
  end

  if not State.tabs[tab] then
    State.tabs[tab] = {
      attached_buffers = {},
    }
  end

  if not State.bufs[buf] then
    State.bufs[buf] = {
      attached_tabs = {},
    }
  end

  local tabmeta = State.tabs[tab]
  local bufmeta = State.bufs[buf]

  local changed = false

  if not vim.tbl_contains(tabmeta.attached_buffers, buf) then
    table.insert(tabmeta.attached_buffers, buf)
    changed = true
  end

  if not vim.tbl_contains(bufmeta.attached_tabs, tab) then
    table.insert(bufmeta.attached_tabs, tab)
    changed = true
  end

  if changed then
    BufNameCache = {}
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

  if vim.bo[buf].modified then
    local bufname = vim.fn.bufname(buf)
    local ok, choice = pcall(
      vim.fn.confirm,
      ('Save changes to %q?'):format(bufname),
      '&Yes\n&No\n&Cancel'
    )
    if not ok or choice == 0 or choice == 3 then
      return
    elseif choice == 1 then -- Yes
      vim.api.nvim_buf_call(buf, vim.cmd.write)
      vim.api.nvim_echo({ { 'Written file ' .. bufname } }, false, {})
    end -- if choose `No` then do nothing. it willbe vacuumed silently
  end

  local bufmeta = State.bufs[buf]
  local tabmeta = State.tabs[tab]

  if not tabmeta then
    vim.notify(
      '[Detach] Cannot find tab meta :`' .. tab .. '`',
      vim.log.levels.ERROR,
      { title = LOG_TITLE }
    )
    return
  end

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

  -- Metadata cleanup
  if bufmeta then
    remove_value(bufmeta.attached_tabs, tab)
  else
    vim.notify(
      '[Detach] Cannot find buf `' .. buf .. '` meta',
      vim.log.levels.ERROR,
      { title = LOG_TITLE }
    )
  end

  remove_value(tabmeta.attached_buffers, buf)

  -- refresh buflisted
  refresh_projection(vim.api.nvim_get_current_tabpage())

  -- Cache invalid
  BufNameCache = {}
end

--- Close a buffer, detach from all tabs
---@param buf?  integer
---@param policy? DetachPolicy
function M.evict(buf, policy)
  if not buf or buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  local meta = State.bufs[buf]
  if not meta then
    return
  end
  policy = policy or 'replace'
  local attached_tabs = vim.deepcopy(meta.attached_tabs)
  for _, tabnr in ipairs(attached_tabs) do
    M.detach(buf, tabnr, policy)
  end
  vim.api.nvim_buf_delete(buf, {})
end

--- Clean orphaned buffers
---@param verbose? boolean
function M.vacuum(verbose)
  verbose = verbose or false
  local orphaned = M.get_orphaned_buf()
  if verbose then
    if #orphaned == 0 then
      vim.api.nvim_echo({ { 'No orphaned buffers', 'Directory' } }, false, {})
    else
      vim.api.nvim_echo({ { 'Vacuumed buffers:', 'Directory' } }, false, {})
    end
  end
  for _, bufnr in ipairs(orphaned) do
    if verbose then
      vim.api.nvim_echo(
        { { vim.api.nvim_buf_get_name(bufnr), 'Directory' } },
        false,
        {}
      )
    end
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
end

--- Get an array of buffer handles of a tab
---@param tab? integer
---@return integer[]
function M.get_attached_buf(tab)
  tab = tab or vim.api.nvim_get_current_tabpage()
  local data = State.tabs[tab]
  if not data then
    return {}
  end
  return vim.list_slice(data.attached_buffers)
end

--- Focus on next buffer
function M.next_buf()
  local bufnr = vim.api.nvim_get_current_buf()
  local tabid = vim.api.nvim_get_current_tabpage()
  local meta = State.tabs[tabid]
  if not meta then
    return
  end
  local bufs = meta.attached_buffers
  local idx
  for i, b in ipairs(bufs) do
    if b == bufnr then
      idx = i
      break
    end
  end
  if not idx then
    return
  end
  local next_idx = idx % #bufs + 1
  local target = bufs[next_idx]
  if not target then
    return
  end
  vim.api.nvim_set_current_buf(target)
end

--- Focus on prev buffer
function M.prev_buf()
  local bufnr = vim.api.nvim_get_current_buf()
  local tabid = vim.api.nvim_get_current_tabpage()
  local meta = State.tabs[tabid]
  if not meta then
    return
  end
  local bufs = meta.attached_buffers
  local idx
  for i, b in ipairs(bufs) do
    if b == bufnr then
      idx = i
      break
    end
  end
  if not idx then
    return
  end
  local next_idx = (idx - 2) % #bufs + 1
  local target = bufs[next_idx]
  if not target then
    return
  end
  vim.api.nvim_set_current_buf(target)
end

--- Get orphaned buffer list
---@return integer[]
function M.get_orphaned_buf()
  local ret = {}
  for bufnr, info in pairs(State.bufs) do
    if not info.attached_tabs or #info.attached_tabs == 0 then
      table.insert(ret, bufnr)
    end
  end
  return ret
end

--- Resolve unique buffer name
---@param bufnr integer
---@return string
function M.resolve_bufname(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return '[Invalid]'
  end
  local name = BufNameCache[bufnr]
  if name then
    return name
  else
    -- Use resolver to calculate unique shortest name
    -- Fill BufNameCache
    local bufs = vim.tbl_keys(State.bufs)
    local Map = {}
    for _, buf in ipairs(bufs) do
      Map[buf] = vim.api.nvim_buf_get_name(buf)
    end
    BufNameCache = Resolver.shortest_unique_suffix(Map)
  end
  return BufNameCache[bufnr] or '[Invalid]'
end

--- Get resolved tabname
---@param tabid integer
---@return string
function M.resolve_tabname(tabid)
  local meta = State.tabs[tabid]
  if not meta then
    return 'Invalid'
  end
  return meta.name or string.format('%d', tabid)
end

--- Rename a tab
---@param tabid integer
---@param new_name string
function M.rename_tab(tabid, new_name)
  local meta = State.tabs[tabid]
  if not meta then
    return
  end
  meta.name = new_name
  vim.cmd [[ redrawtabline ]]
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
  M.vacuum(false)

  ---@type BufferPoolManagerDumpedState
  local to_dump = {
    tabs = {},
    bufs = {},
  }

  -- bufnr -> idx
  local bufnr_index = {}

  -- build buffer path index
  for bufnr, _ in pairs(State.bufs) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      if vim.bo[bufnr].buftype == '' then
        local path = vim.api.nvim_buf_get_name(bufnr)
        if path ~= '' then
          local idx = #to_dump.bufs + 1
          to_dump.bufs[idx] = path
          bufnr_index[bufnr] = idx
        end
      end
    end
  end

  local tabs = vim.api.nvim_list_tabpages()
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

--- Replace state from given json
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

  --- Sweep old states
  State.tabs = {}
  State.bufs = {}

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
          vim.cmd(' doautocmd BufReadPre ' .. bufnr)
          vim.cmd(' doautocmd BufRead ' .. bufnr)
          vim.cmd(' doautocmd BufReadPost ' .. bufnr)
          vim.cmd 'filetype detect'
        end)
        path_index[path] = bufnr
      end
    end
  end

  local bufs = dumped.bufs
  local tabs = dumped.tabs

  local curr_tabs = vim.api.nvim_list_tabpages()
  for i, tab_handle in ipairs(curr_tabs) do
    local dumped_meta = tabs[i]
    if dumped_meta then
      ---@type TabMeta
      local meta = {
        name = dumped_meta.name,
        attached_buffers = {},
      }

      for _, idx in ipairs(dumped_meta.bufs) do
        local path = bufs[idx]
        if path and path ~= '' then
          local bufnr = path_index[path]
          if bufnr then
            if not State.bufs[bufnr] then
              State.bufs[bufnr] = { attached_tabs = {} }
            end
            table.insert(State.bufs[bufnr].attached_tabs, tab_handle)
            table.insert(meta.attached_buffers, bufnr)
          else
            vim.notify(
              '`' .. path .. '`not in path index!',
              vim.log.levels.WARN,
              { title = LOG_TITLE }
            )
          end
        end
      end

      State.tabs[tab_handle] = meta
    end
  end
  refresh_projection(vim.api.nvim_get_current_tabpage())
end

function M.install_hooks()
  local augroup =
    vim.api.nvim_create_augroup('BufferPoolManager', { clear = true })

  ------------------------------------------------------------------------------
  -- Attach newly created/opened buffers
  ------------------------------------------------------------------------------

  -- Add to pool
  vim.api.nvim_create_autocmd('BufAdd', {
    group = augroup,
    callback = function(args)
      local buf = args.buf

      if vim.bo[buf].buftype ~= '' then
        return
      end

      if not State.bufs[buf] then
        State.bufs[buf] = {
          attached_tabs = {},
        }

        BufNameCache = {}
      end
    end,
  })

  -- apply attachment
  vim.api.nvim_create_autocmd('BufWinEnter', {
    group = augroup,
    callback = function(args)
      local buf = args.buf

      M.attach(buf, vim.api.nvim_get_current_tabpage())
    end,
  })

  ------------------------------------------------------------------------------
  -- Cleanup wiped buffers
  ------------------------------------------------------------------------------

  vim.api.nvim_create_autocmd('BufWipeout', {
    group = augroup,
    callback = function(args)
      local buf = args.buf

      local meta = State.bufs[buf]

      if meta then
        for _, tab in ipairs(meta.attached_tabs) do
          local tabmeta = State.tabs[tab]

          if tabmeta then
            remove_value(tabmeta.attached_buffers, buf)
          end
        end
        State.bufs[buf] = nil
      else
        return
      end

      BufNameCache = {}
    end,
  })

  ------------------------------------------------------------------------------
  -- Cleanup closed tabs
  ------------------------------------------------------------------------------

  vim.api.nvim_create_autocmd('TabClosed', {
    group = augroup,
    callback = function()
      local valid_tabs = {}

      for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        valid_tabs[tab] = true
      end

      for tab, meta in pairs(State.tabs) do
        if not valid_tabs[tab] then
          for _, buf in ipairs(meta.attached_buffers) do
            local bufmeta = State.bufs[buf]

            if bufmeta then
              remove_value(bufmeta.attached_tabs, tab)
            end
          end

          State.tabs[tab] = nil
        end
      end
    end,
  })

  ------------------------------------------------------------------------------
  -- Path/name changed
  ------------------------------------------------------------------------------

  vim.api.nvim_create_autocmd('BufFilePost', {
    group = augroup,
    callback = function()
      BufNameCache = {}
    end,
  })

  ------------------------------------------------------------------------------
  -- Recompute masking
  ------------------------------------------------------------------------------

  vim.api.nvim_create_autocmd('TabLeave', {
    group = augroup,
    callback = function()
      mark_buflisted(false)
    end,
  })

  vim.api.nvim_create_autocmd('TabEnter', {
    group = augroup,
    callback = function()
      mark_buflisted(true)
    end,
  })
end

function M.debug_dump()
  print(vim.inspect(State))
end

--- Deprecate current internal state
--- Rebuild via current nvim state -- all buffers attach to first tab
--- Solve problem for cli args loaded bufs
function M.sync()
  State.tabs = {}
  State.bufs = {}

  local tab = vim.api.nvim_get_current_tabpage()

  local tabmeta = {
    attached_buffers = {},
  }

  State.tabs[tab] = tabmeta

  local seen = {}

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if not seen[buf] then
      seen[buf] = true
      if
        vim.api.nvim_buf_is_valid(buf)
        and vim.bo[buf].buflisted
        and vim.bo[buf].buftype == ''
      then
        if not State.bufs[buf] then
          State.bufs[buf] = {
            attached_tabs = { tab },
          }
          table.insert(tabmeta.attached_buffers, buf)
        end
      end
    end
  end

  refresh_projection(vim.api.nvim_get_current_tabpage())

  BufNameCache = {}
end

return M

--------------------------------------------------------------------------------
-- BufferPoolManager -- calculate buffer to display per tab
--------------------------------------------------------------------------------
local M = {}
local LOG_TITLE = 'BufferPoolManager'
---@type BufferPoolManagerOptions
local BUFFER_POOL_MANAGER_OPTIONS_DEFAULT = {
  buftype_policy = {
    [''] = 'managed',

    ---------------------------------------------------------------------------
    -- Active resources
    ---------------------------------------------------------------------------
    terminal = 'external',

    ---------------------------------------------------------------------------
    -- Ephemeral UI
    ---------------------------------------------------------------------------
    help = 'ephemeral',
    quickfix = 'ephemeral',
    nofile = 'ephemeral',
    prompt = 'ephemeral',

    ---------------------------------------------------------------------------
    -- Write-only buffers
    ---------------------------------------------------------------------------
    acwrite = 'ephemeral',

    ---------------------------------------------------------------------------
    -- Plugin generated
    ---------------------------------------------------------------------------
    popup = 'ephemeral',
  },
  default_buftype_policy = 'ephemeral',
}

local Resolver = require 'core.bpm.resolver'
local Opts = vim.deepcopy(BUFFER_POOL_MANAGER_OPTIONS_DEFAULT)

--- BufferPoolManager Global State
local State = {
  ---@type table<integer, TabMeta>
  tabs = {},

  ---@type table<integer, boolean>
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
---@return BufTypePolicy
local function get_buftype_policy(buf)
  return Opts.buftype_policy[vim.bo[buf].buftype] or Opts.default_buftype_policy
end

---@param buf integer
---@return boolean
function M.is_managed(buf)
  return get_buftype_policy(buf) == 'managed'
end

--- Attach buffer to a tab
---@param buf integer
---@param tab integer
function M.attach(buf, tab)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  -- skip special buffers
  if not M.is_managed(buf) then
    return
  end

  if not State.tabs[tab] then
    State.tabs[tab] = {
      attached_buffers = {},
    }
  end

  State.bufs[buf] = true
  local tabmeta = State.tabs[tab]

  local changed = false

  if not vim.tbl_contains(tabmeta.attached_buffers, buf) then
    table.insert(tabmeta.attached_buffers, buf)
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

  if vim.bo[buf].modifiable and vim.bo[buf].modified then
    local bufname = vim.fn.bufname(buf)
    local ok, choice = pcall(
      vim.fn.confirm,
      ('Save changes to %q?'):format(bufname),
      '&Yes\n&No\n&Cancel'
    )
    if not ok or choice == 0 or choice == 3 then
      return
    elseif choice == 1 then -- Yes
      local ok_write, err = pcall(vim.api.nvim_buf_call, buf, vim.cmd.write)
      if not ok_write then
        vim.notify(
          'Write file `' .. bufname .. '` failed, because' .. err,
          vim.log.levels.ERROR,
          { title = LOG_TITLE }
        )
        return
      end
      vim.api.nvim_echo({ { 'Written file ' .. bufname } }, false, {})
    end -- if choose `No` then do nothing. it will be vacuumed silently
  end

  local buftype_policy = get_buftype_policy(buf)

  local tabmeta = State.tabs[tab]

  if buftype_policy == 'managed' then
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

    remove_value(tabmeta.attached_buffers, buf)
    vim.bo[buf].buflisted = false
  elseif buftype_policy == 'external' then
    if tabmeta then
      remove_value(tabmeta.attached_buffers, buf)
    end
    vim.bo[buf].buflisted = false
  elseif buftype_policy == 'ephemeral' then
    vim.api.nvim_buf_delete(buf, { force = true })
  end

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
  policy = policy or 'replace'
  for tab, meta in pairs(State.tabs) do
    if vim.tbl_contains(meta.attached_buffers, buf) then
      M.detach(buf, tab, policy)
    end
  end
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, {})
  end
end

--- Clean orphaned buffers
---@param verbose? boolean
function M.vacuum(verbose)
  verbose = verbose or false
  local orphaned = M.get_orphaned_buf()
  if verbose then
    if #orphaned == 0 then
      vim.api.nvim_echo({ { 'No orphaned buffers', 'WarningMsg' } }, false, {})
    else
      vim.api.nvim_echo({ { 'Vacuumed buffers:', 'MoreMsg' } }, false, {})
    end
  end
  for _, bufnr in ipairs(orphaned) do
    if verbose then
      vim.api.nvim_echo(
        { { vim.api.nvim_buf_get_name(bufnr), 'MoreMsg' } },
        false,
        {}
      )
    end
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
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

--- Get orphaned buffer list
---@return integer[]
function M.get_orphaned_buf()
  local ret = {}
  local attached = {}
  for _, meta in pairs(State.tabs) do
    for _, bufnr in ipairs(meta.attached_buffers) do
      attached[bufnr] = true
    end
  end
  for _, bufnr in ipairs(vim.tbl_keys(State.bufs)) do
    if vim.api.nvim_buf_is_valid(bufnr) and not attached[bufnr] then
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

  if not BufNameCache[bufnr] then
    -- Fallback to filename
    BufNameCache[bufnr] =
      vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':t')
  end
  return BufNameCache[bufnr]
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

local function is_valid(buf_num)
  if not buf_num or buf_num < 1 then
    return false
  end
  local exists = vim.api.nvim_buf_is_valid(buf_num)
  return vim.bo[buf_num].buflisted and exists
end

local function get_listed_bufs()
  local buf_nums = vim.tbl_keys(State.bufs)
  local ids = {}
  for _, buf in ipairs(buf_nums) do
    if is_valid(buf) then
      ids[#ids + 1] = buf
    end
  end
  return ids
end

local function on_tab_leave()
  local listed = get_listed_bufs()
  local tab = vim.api.nvim_get_current_tabpage()
  local meta = State.tabs[tab]
  if not meta then
    return
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

  -- force vacuum orphaned buffers
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
      if M.is_managed(bufnr) then
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

--- Import serialized state into current BPM graph.
---
--- Existing managed buffers and tabs are preserved.
--- Session data is merged into the current runtime state.
---
--- This function does NOT replace the current state.
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
          vim.api.nvim_exec_autocmds('BufReadPre', { buffer = bufnr })
          vim.api.nvim_exec_autocmds('BufRead', { buffer = bufnr })
          vim.api.nvim_exec_autocmds('BufReadPost', { buffer = bufnr })
          vim.api.nvim_exec_autocmds('FileType', { buffer = bufnr })
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
      -- check if has current state
      local existing_meta = State.tabs[tabid]
      if not existing_meta then
        existing_meta = {
          attached_buffers = {},
        }
        State.tabs[tabid] = existing_meta
      end

      -- merge tabname: if not renamed current tab, use the tab restored
      if not existing_meta.name and dumped_meta.name then
        existing_meta.name = dumped_meta.name
      end

      for _, idx in ipairs(dumped_meta.bufs) do
        local path = bufs[idx]
        if path and path ~= '' then
          local bufnr = path_index[path]
          if bufnr then
            State.bufs[bufnr] = true
            if not vim.tbl_contains(existing_meta.attached_buffers, bufnr) then
              table.insert(existing_meta.attached_buffers, bufnr)
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
    end
  end
end

local function install_autocmds()
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

      if not M.is_managed(buf) then
        return
      end

      if vim.bo[buf].buflisted then
        M.attach(buf, vim.api.nvim_get_current_tabpage())
      end

      if not State.bufs[buf] then
        State.bufs[buf] = true

        BufNameCache = {}
      end
    end,
  })

  ------------------------------------------------------------------------------
  -- Cleanup wiped buffers
  ------------------------------------------------------------------------------

  vim.api.nvim_create_autocmd('BufWipeout', {
    group = augroup,
    callback = function(args)
      local buf = args.buf
      State.bufs[buf] = nil
      for _, meta in pairs(State.tabs) do
        remove_value(meta.attached_buffers, buf)
      end
      BufNameCache = {}
    end,
  })

  ------------------------------------------------------------------------------
  -- Cleanup closed tabs
  ------------------------------------------------------------------------------

  vim.api.nvim_create_autocmd('TabClosedPre', {
    group = augroup,
    callback = function()
      local to_close = vim.api.nvim_get_current_tabpage()
      -- HACK: Skip the TabLeave event
      -- TabClosed only provides tab number, not tab handle.
      -- Capture handle in TabClosedPre and remove state after close.
      vim.schedule(function()
        State.tabs[to_close] = nil
      end)
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
  -- Recompute masking and sync new buffers
  ------------------------------------------------------------------------------

  vim.api.nvim_create_autocmd('TabLeave', {
    group = augroup,
    callback = on_tab_leave,
  })

  vim.api.nvim_create_autocmd('TabEnter', {
    group = augroup,
    callback = function()
      mark_buflisted(true)
    end,
  })

  vim.api.nvim_create_autocmd('TabNewEntered', {
    group = augroup,
    callback = function()
      local tab = vim.api.nvim_get_current_tabpage()
      State.tabs[tab] = { attached_buffers = {} }
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

  -- All tracked bufs
  append('\nBuffers:\n', 'Title')
  local attached = {}
  for _, meta in pairs(State.tabs) do
    for _, bufnr in ipairs(meta.attached_buffers) do
      attached[bufnr] = true
    end
  end

  for _, bufnr in ipairs(vim.tbl_keys(State.bufs)) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local is_attached = attached[bufnr]
      local modified = vim.bo[bufnr].modified
      append(string.format('  %-3d ', bufnr), 'Number')
      append(M.resolve_bufname(bufnr), is_attached and 'Directory' or 'Comment')
      if modified then
        append(' [+]', 'DiagnosticWarn')
      end
      if not is_attached then
        append(' (orphaned)', 'DiagnosticError')
      end
      append('\n')
    end
  end

  -- Orphaned
  local orphaned = M.get_orphaned_buf()
  append('\nOrphaned: ', 'Title')
  if #orphaned == 0 then
    append('none\n', 'Comment')
  else
    append(tostring(#orphaned) .. '\n', 'DiagnosticError')
    for _, bufnr in ipairs(orphaned) do
      local modified = vim.bo[bufnr].modified
      append(string.format('  %-3d ', bufnr), 'Number')
      append(M.resolve_bufname(bufnr), 'DiagnosticError')
      if modified then
        append(' [+]', 'DiagnosticWarn')
      end
      append('\n')
    end
  end

  vim.api.nvim_echo(chunks, false, {})
end

--- Deprecate current internal state
--- Rebuild via current nvim state -- all buffers attach to first tab
--- Solve problem for cli args loaded bufs
local function rebuild()
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
        and M.is_managed(buf)
      then
        State.bufs[buf] = true
        table.insert(tabmeta.attached_buffers, buf)
      end
    end
  end

  for _, bufnr in ipairs(vim.tbl_keys(State.bufs)) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.bo[bufnr].buflisted = false
    end
  end

  mark_buflisted(true, tab)

  BufNameCache = {}
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

  vim.api.nvim_create_user_command('BpmVacuum', function(args)
    M.vacuum(args.bang)
  end, {
    bang = true,
    desc = 'Delete orphaned buffers (use ! for verbose)',
  })

  vim.api.nvim_create_user_command('BpmEvict', function(args)
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

    for _, bufnr in ipairs(bufnrs) do
      M.evict(bufnr, policy)
    end
  end, {
    nargs = '*',
    complete = function(arglead, cmdline, _)
      local args = vim.split(cmdline, '%s+')
      if #args == 2 then
        return vim.tbl_filter(function(p)
          return p:find(arglead, 1, true)
        end, { 'replace', 'idle', 'destroy' })
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
    complete = function(arglead, cmdline, _)
      local args = vim.split(cmdline, '%s+')
      if #args == 2 then
        return vim.tbl_filter(function(p)
          return p:find(arglead, 1, true)
        end, { 'replace', 'idle', 'destroy' })
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

  vim.api.nvim_create_user_command('BpmDebugRebuild', function()
    rebuild()
    vim.notify(
      'Buffer pool state rebuilt',
      vim.log.levels.INFO,
      { title = LOG_TITLE }
    )
  end, { desc = 'Rebuild internal state from current buffers (debug)' })

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

---@param opts? BufferPoolManagerOptions
function M.setup(opts)
  Opts = vim.tbl_deep_extend('force', Opts, opts or {})
  install_autocmds()
  install_usercmds()
  -- files via commandline args is not recorded. so we sync here
  rebuild()
end

return M

--------------------------------------------------------------------------------
-- :Sh - Async background command runner
--
-- :Sh runs a single non-interactive command in the background, buffers
-- stdout/stderr until exit, then appends one assembled block to the shell log
-- through `shell.log.append`. Use :! for synchronous filters and commands that
-- modify buffer text.
--
-- Usage:
--   :Sh <cmd>
--   :Sh{interp=bash,timeout=60000,merge_output=false} <cmd>
--   :Sh{} { echo a; echo b; }
--
-- Options:
--   interp        interpreter, default Profile.integrated_terminal_shell
--   timeout       ms, <=0 disables; timeout kills the process group
--   merge_output  true merges stderr into stdout, false emits a separate
--                 Stderr section
--
-- Commands:
--   :Shctl set key=value...  session-only option overrides
--   :Shctl inspect           colored task history dump
--   :Shctl kill <id>...      kill running task process groups
--   :ShellLog                open the shell log buffer
--
-- Setup:
--   require('edit.sh').setup({
--     shctl_opt_str = 'interp=fish timeout=0',
--     interp_profiles = {
--       ['^mytool$'] = { name = 'mytool', build_argv = function(interp, cmd)
--         return { interp, '-c', cmd }
--       end },
--     },
--   })
--
-- Interp profiles:
--   bash, sh, zsh, fish, python* (python -c <source>)
--   Profiles match the executable basename.
--
-- Output:
--   Bus tag `shell.log.append`; content is string[] of complete lines.
--   shell-log normalizes ANSI and appends without line buffering.
--
-- Task status:
--   running / done / failed / killed / error
--   timeout is reported as killed (code 124, signal 15).
--   Finished tasks are retained in memory for :Shctl inspect.
--
-- Completion:
--   - inside `{...}`: option keys/values
--   - after `}`: simple path completion
--   - no shell command, flag, or subcommand completion
--   - suffix-based candidates for blink.cmp
--
-- Limitations:
--   - non-interactive pipe; no pty, so color=auto is disabled
--   - stdin is closed; interactive commands should use :!
--   - output is emitted at exit, not streamed
--   - process-group kill is Unix-only; Windows uses direct-process fallback
--   - commands that daemonize or call setsid may escape the process group
--------------------------------------------------------------------------------
local M = {}

local LOG_TITLE = 'Sh'
local log = require 'utils.logger'.new(LOG_TITLE)
local Clock = require 'utils.clock'

local AUG = vim.api.nvim_create_augroup('AsyncSh', { clear = true })

local lbind = require 'utils.fnx'.lbind
local sorted_pairs = require 'utils.tblx'.sorted_pairs

---@class InterpProfile
---@field name string
---@field build_argv fun(interp: string, cmd: string): string[]

---@type table<string, InterpProfile>
local InterpProfiles = {
  ['^bash$'] = {
    name = 'bash',
    build_argv = function(interp, cmd)
      return { interp, '-c', cmd }
    end,
  },

  ['^sh$'] = {
    name = 'sh',
    build_argv = function(interp, cmd)
      return { interp, '-c', cmd }
    end,
  },

  ['^zsh$'] = {
    name = 'zsh',
    build_argv = function(interp, cmd)
      return { interp, '-c', cmd }
    end,
  },

  ['^fish$'] = {
    name = 'fish',
    build_argv = function(interp, cmd)
      return { interp, '-c', cmd }
    end,
  },

  ['^python[%d%.]*$'] = {
    name = 'python',
    build_argv = function(interp, cmd)
      return { interp, '-c', cmd }
    end,
  },
}

---@class ShInitOpt
---@field shctl_opt_str? string
---@field interp_profiles? table<string, InterpProfile> pattern - profile

---@class ShctlOpt
---@field timeout integer command timeout in ms, 0 or negative means no time limit
---@field interp string default interpreter
---@field merge_output boolean merge stdout and stderr
local SHCTL_OPT_DEFAULT = {
  interp = Profile.integrated_terminal_shell,
  timeout = 0,
  merge_output = true,
}

local sprintf = string.format

---@alias ShTaskStat
---|'running' still working
---|'done'    exit ok
---|'killed'  signal non-zero
---|'failed'  exit-code non-zero
---|'error'   unknown error

---@class ShTask
---@field stat ShTaskStat
---@field id integer
---@field o  ShctlOpt
---@field proc vim.SystemObj?
---@field pid  integer?
---@field emsg_buf string[]
---@field stdout_buf string[]
---@field stderr_buf string[]
---@field stdout_pending string
---@field stderr_pending string
---@field started_at number
---@field cmdline string
---@field end_at? number
---@field signal? integer
---@field exit_code? integer
---@field timer? uv.uv_timer_t

local ShctlOpt = vim.deepcopy(SHCTL_OPT_DEFAULT)

--- Parse `shctl_opt_str`: `key=value` pairs separated by commas and/or
--- whitespace. Bare keys are treated as boolean `true`.
---
--- Returns `nil, err` on failure. Command handlers should abort on error;
--- `setup()` logs the error and keeps the defaults.
---@param str string|nil
---@return table<string, any>|nil, string|nil
local function parse_shctl_opt_str(str)
  if str == nil then
    return {}
  end
  if type(str) ~= 'string' then
    return nil, sprintf('expected string, got %s', type(str))
  end

  local s = str
  local n = #s
  local i = 1
  local opts = {}

  local function skip_seps()
    while i <= n do
      local c = s:sub(i, i)
      if c == ',' or c:match('%s') then
        i = i + 1
      else
        break
      end
    end
  end

  local function skip_spaces()
    while i <= n and s:sub(i, i):match('%s') do
      i = i + 1
    end
  end

  local function fail(fmt, ...)
    return nil, sprintf(fmt, ...)
  end

  while true do
    skip_seps()
    if i > n then
      break
    end

    local ks, ke = s:find('^[_%a][_%w]*', i)
    if not ks then
      return fail('expected option name at %d', i)
    end

    local key = s:sub(ks, ke)
    i = ke + 1
    skip_spaces()

    local raw_value
    if i <= n and s:sub(i, i) == '=' then
      i = i + 1
      skip_spaces()

      local vs, ve = s:find('^[^,%s]+', i)
      if not vs then
        return fail('expected value for option %q at %d', key, i)
      end

      raw_value = s:sub(vs, ve)
      i = ve + 1
    else
      raw_value = true
    end

    if i <= n and not s:sub(i, i):match('[%s,]') then
      return fail('expected separator after option %q at %d', key, i)
    end

    local default = SHCTL_OPT_DEFAULT[key]
    if default == nil then
      local keys = vim.tbl_keys(SHCTL_OPT_DEFAULT)
      table.sort(keys)
      return fail(
        'unknown option %q (valid: %s)',
        key,
        table.concat(keys, ', ')
      )
    end

    if opts[key] ~= nil then
      return fail('duplicate option %q', key)
    end

    local ty = type(default)
    if raw_value == true and ty ~= 'boolean' then
      return fail('option %q requires a value', key)
    end

    if ty == 'number' then
      if type(raw_value) ~= 'string' or not raw_value:match('^[+-]?%d+$') then
        return fail(
          'option %q expects integer, got %q',
          key,
          tostring(raw_value)
        )
      end

      local num = tonumber(raw_value)
      local max_safe_integer = 9007199254740992 -- 2^53
      if
        not num
        or num % 1 ~= 0
        or num < -max_safe_integer
        or num > max_safe_integer
      then
        return fail('option %q expects integer, got %q', key, raw_value)
      end

      opts[key] = num
    elseif ty == 'boolean' then
      local value = type(raw_value) == 'string' and raw_value:lower()
        or raw_value

      if value == true or value == 'true' or value == '1' then
        opts[key] = true
      elseif value == false or value == 'false' or value == '0' then
        opts[key] = false
      else
        return fail(
          'option %q expects boolean, got %q',
          key,
          tostring(raw_value)
        )
      end
    elseif ty == 'string' then
      if type(raw_value) ~= 'string' then
        return fail('option %q expects string', key)
      end
      opts[key] = raw_value
    else
      return fail('option %q has unsupported type %q', key, ty)
    end
  end

  return opts
end

---@type table<integer, ShTask>
local ShTasks = {}

---@param t ShTask
local function flush_stdout(t)
  local lines = vim.split(t.stdout_pending, '\n')
  if #lines <= 1 then
    return
  end
  t.stdout_pending = lines[#lines]
  for i = 1, #lines - 1 do
    table.insert(t.stdout_buf, lines[i])
  end
end

---@param t ShTask
local function flush_stderr(t)
  local lines = vim.split(t.stderr_pending, '\n')
  if #lines <= 1 then
    return
  end
  t.stderr_pending = lines[#lines]
  for i = 1, #lines - 1 do
    table.insert(t.stderr_buf, lines[i])
  end
end

local BUS_TAG = 'shell.log.append'
local TIME_FAIL_STRING = '??:??:??'

---@param ms number?
---@return string
local function format_time(ms)
  if not ms then
    return TIME_FAIL_STRING
  end
  local ok, ret = pcall(os.date, '%H:%M:%S', math.floor(ms / 1000))
  return ok and ret ---@type string
    or TIME_FAIL_STRING
end

---@param t ShTask
---@param sig string|integer
local function kill_task(t, sig)
  if not t.proc then
    return
  end
  local ok, ret = pcall(vim.uv.kill, -t.proc.pid, sig)
  if not ok or ret ~= 0 then
    pcall(t.proc.kill, t.proc, sig)
  end
end

---@param t ShTask
local function start_timeout(t)
  local timeout = t.o.timeout
  if type(timeout) ~= 'number' or timeout <= 0 then
    return
  end

  local timer = vim.uv.new_timer()
  if not timer then
    log.error('Cannot create timeout timer for task %d', t.id)
    return
  end

  t.timer = timer
  local ok, err = pcall(timer.start, timer, math.floor(timeout), 0, function()
    vim.schedule(function()
      if t.stat ~= 'running' then
        return
      end
      kill_task(t, 'sigterm')

      -- kill after grace period
      vim.defer_fn(function()
        if t.stat == 'running' then
          kill_task(t, 'sigkill')
        end
      end, 2000)
    end)
  end)
  if not ok then
    t.timer = nil
    pcall(timer.close, timer)
    log.error('Cannot start timeout timer for task %d: %s', t.id, err)
  end
end

---@param t ShTask
local function stop_timeout(t)
  local timer = t.timer
  t.timer = nil
  if not timer then
    return
  end
  pcall(timer.stop, timer)
  if not timer:is_closing() then
    timer:close()
  end
end

---@param id integer
---@param out vim.SystemCompleted
local function on_exit(id, out)
  local t = ShTasks[id]
  if not t then
    return
  end
  stop_timeout(t)
  local time_ok, now = pcall(Clock.unsafe_gettime)
  if time_ok then
    t.end_at = now
  end
  t.signal = out.signal
  t.exit_code = out.code
  t.proc = nil -- release handle
  if t.signal ~= 0 then
    t.stat = 'killed'
  elseif t.exit_code ~= 0 then
    t.stat = 'failed'
  else
    t.stat = 'done'
  end
  flush_stdout(t)
  flush_stderr(t)
  if #t.stderr_pending > 0 then
    table.insert(t.stderr_buf, t.stderr_pending)
  end
  t.stderr_pending = nil
  if #t.stdout_pending > 0 then
    table.insert(t.stdout_buf, t.stdout_pending)
  end
  t.stdout_pending = nil

  local lines = {}
  local function line_appendf(fmt, ...)
    table.insert(lines, sprintf(fmt, ...))
  end
  local function line_append_raw(s)
    table.insert(lines, s)
  end
  local start_time_s = format_time(t.started_at)
  local end_time_s = format_time(t.end_at)

  if t.signal ~= 0 or t.exit_code ~= 0 then
    log.warn(
      'Async shell command %d failed\nexit_code=%d, signal=%d, started_at %s\ncmdline: %s',
      t.id,
      t.exit_code,
      t.signal,
      start_time_s,
      t.cmdline
    )
  else
    log.info(
      'Async shell command %d done\nexit_code=%d, signal=%d, started_at %s\ncmdline: %s',
      t.id,
      t.exit_code,
      t.signal,
      start_time_s,
      t.cmdline
    )
  end

  line_appendf(
    'Async shell cmd id=%d interp=%s, exit=%s, signal=%s %s-%s',
    t.id,
    t.o.interp,
    t.exit_code and tostring(t.exit_code) or '?',
    t.signal and tostring(t.signal) or '?',
    start_time_s,
    end_time_s
  )
  line_appendf('Cmdline: %s', t.cmdline)
  if #t.emsg_buf > 0 then
    line_appendf('Errors:')
    for _, emsg in ipairs(t.emsg_buf) do
      local emsg_lines = vim.split(emsg, '\n')
      line_append_raw('- ' .. emsg_lines[1])
      for i = 2, #emsg_lines do
        line_append_raw(emsg_lines[i])
      end
    end
  end
  line_appendf('Stdout:')
  for _, l in ipairs(t.stdout_buf) do
    line_append_raw(l)
  end
  if not t.o.merge_output then
    line_appendf('Stderr:')
    for _, l in ipairs(t.stderr_buf) do
      line_append_raw(l)
    end
  end

  Bus.emit(BUS_TAG, vim.log.levels.INFO, lines)
end

---@param id integer
---@param err string?
---@param data string?
local function on_stdout(id, err, data)
  local t = ShTasks[id]
  if err then
    table.insert(t.emsg_buf, err)
  end
  if data then
    t.stdout_pending = t.stdout_pending .. data
    flush_stdout(t)
  end
end

---@param id integer
---@param err string?
---@param data string?
local function on_stderr(id, err, data)
  local t = ShTasks[id]
  if t.o.merge_output then
    on_stdout(id, err, data)
    return
  end
  if err then
    table.insert(t.emsg_buf, err)
  end
  if data then
    t.stderr_pending = t.stderr_pending .. data
    flush_stderr(t)
  end
end

local _next_id = 1
local function alloc_task_id()
  local id = _next_id
  _next_id = _next_id + 1
  return id
end

--- Split the leading `{...}` option block from the raw `:Sh` arguments.
--- Everything after the closing `}` is the shell command, unmodified.
---@param raw string
---@return string|nil opt_str
---@return string|nil cmd
---@return string|nil err
local function split_sh_args(raw)
  local leading = raw:match '^%s*' or ''
  local start = #leading + 1
  if raw:sub(start, start) ~= '{' then
    return nil, raw, nil
  end

  local depth = 0
  local close
  for i = start, #raw do
    local c = raw:sub(i, i)
    if c == '{' then
      depth = depth + 1
    elseif c == '}' then
      depth = depth - 1
      if depth == 0 then
        close = i
        break
      end
    end
  end

  if not close then
    return nil, nil, 'unterminated option block'
  end

  local cmd = raw:sub(close + 1):gsub('^%s+', '')
  return raw:sub(start + 1, close - 1), cmd, nil
end

---@param args vim.api.keyset.create_user_command.command_args
local function cmd_sh(args)
  local opt = vim.deepcopy(ShctlOpt)
  local opt_str, cmd_str, split_err = split_sh_args(args.args)

  if split_err then
    log.error('Invalid option block: %s', split_err)
    return
  end

  if opt_str then
    local parsed, err = parse_shctl_opt_str(opt_str)
    if not parsed then
      log.error('Malformed option string `%s`, emsg: `%s`', opt_str, err)
      return
    end
    opt = vim.tbl_deep_extend('force', opt, parsed)
  end

  if not cmd_str or cmd_str:match '^%s*$' then
    log.error('Empty command')
    return
  end

  local id = alloc_task_id()

  ---@type vim.SystemOpts
  local spawn_opts = {
    stdout = lbind(on_stdout, id),
    stderr = lbind(on_stderr, id),
    detach = true,
  }

  local basename = opt.interp:match('[^/]+$') or opt.interp

  ---@type InterpProfile?
  local interp_prof
  for pat, prof in pairs(InterpProfiles) do
    if string.match(basename, pat) then
      interp_prof = prof
      break
    end
  end
  if not interp_prof then
    log.error('Cannot find a interpreter profile for `%s`', opt.interp)
    return
  end
  local arglist = interp_prof.build_argv(opt.interp, cmd_str)

  local time_ok, now = pcall(Clock.unsafe_gettime)

  if not time_ok then
    log.error('Cannot get time stamp')
    return
  end

  local ok, proc = pcall(vim.system, arglist, spawn_opts, lbind(on_exit, id))

  if not ok then
    log.error('Task %d crete failed, because %s', id, tostring(proc))
  end

  local task = {
    id = id,
    stat = ok and 'running' or 'error',
    proc = ok and proc or nil,
    pid = ok and proc.pid or nil,
    o = opt,
    emsg_buf = {},
    stderr_buf = {},
    stdout_buf = {},
    cmdline = cmd_str,
    stdout_pending = '',
    stderr_pending = '',
    started_at = now,
  }

  ShTasks[id] = task
  start_timeout(task)
end

local STAT_HL = {
  running = 'DiagnosticInfo',
  done = 'DiagnosticOk',
  failed = 'DiagnosticError',
  killed = 'DiagnosticWarn',
  error = 'DiagnosticError',
}

---@param ms number?
---@return string
local function format_duration(ms)
  if not ms or ms < 0 then
    return '?'
  end
  if ms < 1000 then
    return sprintf('%dms', math.floor(ms))
  end
  return sprintf('%.1fs', ms / 1000)
end

---@return {[1]:string,[2]:string}[]
local function build_inspect_chunks()
  local chunks = {}
  ---@param str string
  ---@param hl? string
  local function add(str, hl)
    chunks[#chunks + 1] = { str, hl or 'Normal' }
  end

  add('Shctl:\n', 'Title')
  add('  interp=', 'Comment')
  add(ShctlOpt.interp, 'Special')
  add('  timeout=', 'Comment')
  add(tostring(ShctlOpt.timeout), 'Number')
  add('  merge_output=', 'Comment')
  add(tostring(ShctlOpt.merge_output), 'Special')
  add('\n\n', 'Normal')

  add(sprintf('Sh tasks (%d):\n', vim.tbl_count(ShTasks)), 'Title')
  if vim.tbl_isempty(ShTasks) then
    add('  (none)\n', 'Comment')
    return chunks
  end

  for id, t in sorted_pairs(ShTasks) do
    add(sprintf('  #%-3d ', id), 'Number')
    add(sprintf('[%s]', t.stat), STAT_HL[t.stat] or 'Normal')

    if t.o.interp ~= ShctlOpt.interp then
      add('  interp=', 'Comment')
      add(t.o.interp, 'Special')
    end

    if t.pid then
      add('  pid=', 'Comment')
      add(tostring(t.pid), 'Number')
    end

    local end_at = t.end_at
    if not end_at and t.stat == 'running' then
      local ok, now = pcall(Clock.unsafe_gettime)
      end_at = ok and now or nil
    end
    local duration = end_at and (end_at - t.started_at) or nil
    add(t.stat == 'running' and '  elapsed=' or '  duration=', 'Comment')
    add(format_duration(duration), 'Number')
    add('\n', 'Normal')

    add('      cmd: ', 'Comment')
    add(t.cmdline .. '\n', 'Normal')

    add('      start=', 'Comment')
    add(format_time(t.started_at), 'Special')
    add('  end=', 'Comment')
    add(format_time(t.end_at), 'Special')
    add('  exit=', 'Comment')
    add(t.exit_code and tostring(t.exit_code) or '-', 'Number')
    add('  signal=', 'Comment')
    add(t.signal and tostring(t.signal) or '-', 'Number')
    add('\n', 'Normal')

    add('      out=', 'Comment')
    add(tostring(#t.stdout_buf), 'Number')
    add(' lines  err=', 'Comment')
    add(tostring(#t.stderr_buf), 'Number')
    add(' lines  errors=', 'Comment')
    add(
      tostring(#t.emsg_buf),
      #t.emsg_buf > 0 and 'DiagnosticError' or 'Number'
    )
    add('\n\n', 'Normal')
  end

  return chunks
end

local function inspect(_)
  vim.api.nvim_echo(build_inspect_chunks(), false, {})
end

---@class ShctlSubcommandSpec
---
---@field handler fun(args:vim.api.keyset.create_user_command.command_args)
---@field comp_fn fun(ctx:ShctlCompleteCtx):string[]

---@class ShctlCompleteCtx
---@field subcmd? string
---@field arg string

---@param with_eq boolean
---@param fragment? string
---@return string[]
local function complete_option_keys(with_eq, fragment)
  fragment = fragment or ''
  local out = {}
  local keys = vim.tbl_keys(SHCTL_OPT_DEFAULT)
  table.sort(keys)
  for _, key in ipairs(keys) do
    if fragment == '' or vim.startswith(key, fragment) then
      out[#out + 1] = with_eq and (key .. '=') or key
    end
  end
  return out
end

---@param fragment string
---@return string[]
local function complete_interp_value(fragment)
  -- Command names for `interp=zsh`, paths for `interp=/usr/bin/python`.
  local kind = (fragment:find '/' or fragment:match '^[~.]') and 'file'
    or 'shellcmd'

  local out = {}
  local seen = {}
  local ok, matches = pcall(vim.fn.getcompletion, fragment, kind)
  if ok then
    for _, match in ipairs(matches) do
      local cand = match
      if fragment ~= '' and vim.startswith(cand, fragment) then
        cand = cand:sub(#fragment + 1)
      end
      if cand ~= '' and not seen[cand] then
        seen[cand] = true
        out[#out + 1] = cand
      end
    end
  end
  return out
end

---@param key? string
---@param fragment string
---@return string[]
local function complete_option_value(key, fragment)
  if not key then
    return {}
  end

  if key == 'interp' then
    return complete_interp_value(fragment)
  elseif type(SHCTL_OPT_DEFAULT[key]) == 'boolean' then
    local out = {}
    local value = fragment:lower()
    for _, cand in ipairs { 'true', 'false' } do
      if vim.startswith(cand, value) then
        out[#out + 1] = cand
      end
    end
    return out
  end

  return {}
end

---@param text string
---@return string[]
local function complete_sh_cmd_path(text)
  local words = {}
  for word in text:gmatch '%S+' do
    words[#words + 1] = word
  end

  local trailing_space = text:match '%s$' ~= nil
  local current = trailing_space and '' or (words[#words] or '')
  local has_prev
  if trailing_space then
    has_prev = #words > 0
  else
    has_prev = #words > 1
  end

  local path_like = current:match '^[/~.]' ~= nil
    or current:find('/', 1, true) ~= nil
  if not has_prev and not path_like then
    return {}
  end

  local ok, matches = pcall(vim.fn.getcompletion, current, 'file')
  if not ok then
    return {}
  end

  local out = {}
  for _, cand in ipairs(matches) do
    local suffix = cand
    if current ~= '' and vim.startswith(cand, current) then
      suffix = cand:sub(#current + 1)
    end
    if suffix ~= '' then
      out[#out + 1] = suffix
    end
  end
  return out
end

---@type table<string, ShctlSubcommandSpec>
local SHCTL_SUBCOMMANDS = {
  inspect = {
    handler = inspect,
    comp_fn = function(_)
      return {}
    end,
  },
  set = {
    handler = function(args)
      local opt_str = ''
      local argv = args.fargs
      for i = 2, #argv do
        opt_str = opt_str .. ' ' .. argv[i]
      end
      local opt, err = parse_shctl_opt_str(opt_str)
      if not opt then
        log.error('Cannot parse option string: %s', err)
        return
      end
      ShctlOpt = vim.tbl_deep_extend('force', ShctlOpt, opt)
    end,
    comp_fn = function(ctx)
      local pair = ctx.arg:match '([^,]*)$' or ctx.arg
      local key, value = pair:match '^([^=]+)=(.*)$'
      if key then
        return complete_option_value(key, value)
      end
      return complete_option_keys(true, pair)
    end,
  },
  kill = {
    handler = function(args)
      local to_kill = {}
      local argv = args.fargs
      for i = 2, #argv do
        local id = tonumber(argv[i])
        if id then
          table.insert(to_kill, id)
        else
          log.error('Malformed task id `%s`', argv[i])
        end
      end

      for _, id in ipairs(to_kill) do
        local t = ShTasks[id]
        if not t then
          log.error('Invalid task `%d`', id)
          goto continue
        end

        if t.stat ~= 'running' then
          log.warn('Task %d already stopped', id)
          goto continue
        end

        if not t.proc then
          log.error('Task %d does not have a valid proc handle', id)
          goto continue
        end

        kill_task(t, 'sigkill')

        ::continue::
      end
    end,
    comp_fn = function(_)
      local ret = {}
      for id, t in sorted_pairs(ShTasks) do
        if t.stat == 'running' then
          table.insert(ret, tostring(id))
        end
      end
      return ret
    end,
  },
}

---@param args vim.api.keyset.create_user_command.command_args
local function cmd_shctl(args)
  local argv = args.fargs
  if #argv == 0 then
    SHCTL_SUBCOMMANDS.inspect.handler(args)
    return
  end

  local spec = SHCTL_SUBCOMMANDS[argv[1]]

  if spec and spec.handler then
    spec.handler(args)
    return
  end

  log.error('Unknown shctl subcommand `%s`', argv[1])
end

--- Find the leading `{...}` options block and return its text before cursor.
--- Returns nil when the cursor is before the block or after its closing `}`.
---@param cmdline string
---@param cursorpos integer 0-based byte index
---@return integer|nil brace_pos
---@return string|nil block_text
local function get_sh_opt_block(cmdline, cursorpos)
  local before = cmdline:sub(1, cursorpos)
  local start = before:find '%S'
  if not start then
    return nil
  end

  if before:sub(start, start) == ':' then
    start = start + 1
  end

  if before:sub(start, start + 1) ~= 'Sh' then
    return nil
  end

  local pos = start + 2
  while pos <= #before and before:sub(pos, pos):match '%s' do
    pos = pos + 1
  end

  if before:sub(pos, pos) ~= '{' then
    return nil
  end

  local depth = 0
  for i = pos, #before do
    local c = before:sub(i, i)
    if c == '{' then
      depth = depth + 1
    elseif c == '}' then
      depth = depth - 1
      if depth == 0 then
        -- No completion after the options block.
        return nil
      end
    end
  end

  return pos, before:sub(pos + 1)
end

--- Return the text after the leading `{...}` block. Returns nil while the
--- cursor is still inside the block.
---@param cmdline string
---@param cursorpos integer
---@return string|nil
local function get_sh_cmd_prefix(cmdline, cursorpos)
  local before = cmdline:sub(1, cursorpos)
  local start = before:find '%S'
  if not start then
    return nil
  end

  if before:sub(start, start) == ':' then
    start = start + 1
  end

  if before:sub(start, start + 1) ~= 'Sh' then
    return nil
  end

  local pos = start + 2
  while pos <= #before and before:sub(pos, pos):match '%s' do
    pos = pos + 1
  end

  if before:sub(pos, pos) ~= '{' then
    return before:sub(pos)
  end

  local depth = 0
  for i = pos, #before do
    local c = before:sub(i, i)
    if c == '{' then
      depth = depth + 1
    elseif c == '}' then
      depth = depth - 1
      if depth == 0 then
        return before:sub(i + 1)
      end
    end
  end

  return nil
end

---@class ShCompleteCtx
---@field kind 'key'|'value'
---@field key? string
---@field fragment string

--- Parse the partial options block to determine whether the cursor is in a
--- key or a value.
---@param text string
---@return ShCompleteCtx
local function get_completion_context(text)
  local i = 1
  local n = #text
  local state = 'start'
  local key_start
  local key_end
  local value_start
  local key

  while i <= n do
    local c = text:sub(i, i)

    if state == 'start' then
      if c == ',' or c:match '%s' then
        i = i + 1
      else
        key_start = i
        state = 'key'
      end
    elseif state == 'key' then
      if c:match '[_%w]' then
        i = i + 1
      else
        key_end = i - 1
        key = text:sub(key_start, key_end)
        state = 'after_key'
      end
    elseif state == 'after_key' then
      if c:match '%s' then
        i = i + 1
      elseif c == '=' then
        i = i + 1
        state = 'after_eq'
      else
        i = i + 1
        state = 'start'
        key = nil
      end
    elseif state == 'after_eq' then
      if c:match '%s' then
        i = i + 1
      else
        value_start = i
        state = 'value'
      end
    elseif state == 'value' then
      if c == ',' or c:match '%s' then
        i = i + 1
        state = 'start'
        key = nil
      else
        i = i + 1
      end
    end
  end

  if state == 'key' then
    return { kind = 'key', fragment = text:sub(key_start) }
  elseif state == 'after_key' then
    return { kind = 'key', fragment = text:sub(key_start, key_end or n) }
  elseif state == 'after_eq' then
    return { kind = 'value', key = key, fragment = '' }
  elseif state == 'value' then
    return { kind = 'value', key = key, fragment = text:sub(value_start) }
  end

  return { kind = 'key', fragment = '' }
end

--- Blink's cmdline source calls `getcompletion()` with the text before the
--- current keyword and then prepends that prefix itself. Return only the
--- completion suffix, otherwise the prefix gets duplicated.
---@param _ string
---@param cmdline string
---@param cursorpos integer
---@return string[]
local function complete_sh(_, cmdline, cursorpos)
  local brace_pos, text = get_sh_opt_block(cmdline, cursorpos)
  if brace_pos and text then
    local ctx = get_completion_context(text)

    if ctx.kind == 'key' then
      return complete_option_keys(true, ctx.fragment)
    end

    return complete_option_value(ctx.key, ctx.fragment)
  end

  local cmd_prefix = get_sh_cmd_prefix(cmdline, cursorpos)
  if not cmd_prefix then
    return {}
  end

  return complete_sh_cmd_path(cmd_prefix)
end

---@param cmdline string
---@param cursorpos integer
---@return ShctlCompleteCtx|nil
local function get_shctl_completion_ctx(cmdline, cursorpos)
  local before = cmdline:sub(1, cursorpos)
  local start = before:find '%S'
  if not start then
    return nil
  end

  if before:sub(start, start) == ':' then
    start = start + 1
  end

  if before:sub(start, start + 4) ~= 'Shctl' then
    return nil
  end

  local rest = before:sub(start + 5):gsub('^%s+', '')
  local tokens = {}
  for token in rest:gmatch '%S+' do
    tokens[#tokens + 1] = token
  end
  local trailing_space = rest:match '%s$' ~= nil

  local subcmd
  local arg = ''
  if #tokens == 1 and not trailing_space then
    if SHCTL_SUBCOMMANDS[tokens[1]] then
      subcmd = tokens[1]
    else
      arg = tokens[1]
    end
  elseif #tokens >= 1 then
    subcmd = tokens[1]
    if not trailing_space then
      arg = tokens[#tokens]
    end
  end

  return { subcmd = subcmd, arg = arg }
end

---@param fragment string
---@return string[]
local function complete_shctl_subcmd(fragment)
  local out = {}
  for name, _ in pairs(SHCTL_SUBCOMMANDS) do
    if fragment == '' or vim.startswith(name, fragment) then
      out[#out + 1] = name
    end
  end
  return out
end

---@param _ string
---@param cmdline string
---@param cursorpos integer
---@return string[]
local function complete_shctl(_, cmdline, cursorpos)
  local ctx = get_shctl_completion_ctx(cmdline, cursorpos)
  if not ctx then
    return {}
  end

  if not ctx.subcmd then
    return complete_shctl_subcmd(ctx.arg)
  end

  local spec = SHCTL_SUBCOMMANDS[
    ctx.subcmd --[[@as string]]
  ]

  if spec and spec.comp_fn then
    return spec.comp_fn(ctx)
  end

  return {}
end

local _initialized = false

---@param opts? ShInitOpt
function M.setup(opts)
  if _initialized then
    log.error('setup function should not be called twice!')
    return
  end

  opts = opts or {}

  if opts.interp_profiles then
    InterpProfiles =
      vim.tbl_extend('force', InterpProfiles, opts.interp_profiles)
  end

  local parsed, err = parse_shctl_opt_str(opts.shctl_opt_str)
  if parsed then
    ShctlOpt = vim.tbl_deep_extend('force', ShctlOpt, parsed)
  else
    log.error('Invalid shctl_opt_str: %s', err)
  end

  vim.api.nvim_create_user_command('Sh', cmd_sh, {
    desc = 'Asynchronously execute shell commands',
    nargs = '*',
    complete = complete_sh,
  })
  vim.api.nvim_create_user_command('Shctl', cmd_shctl, {
    desc = 'The control command of Sh subsystem',
    nargs = '*',
    complete = complete_shctl,
  })

  -- cleanup unfinished task
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = AUG,
    callback = function()
      for _, t in pairs(ShTasks) do
        if t.stat == 'running' and t.proc then
          stop_timeout(t)
          kill_task(t, 'sigkill')
        end
      end
    end,
  })

  _initialized = true
end

return M

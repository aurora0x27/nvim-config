--------------------------------------------------------------------------------
-- Emacs style repl env
--
-- TODO:
-- 1. multi env
-- 2. multi language
--------------------------------------------------------------------------------
local M = {}
local LOG_TITLE = 'Repl'

local bind = require 'utils.loader'.bind

---@class ReplContext
---@field id?  string keep, not used now
---@field env  table

---@alias ReplSrcLoc {[1]: integer, [2]: integer} 0 based range

local CurrCtx

---@return table
local function new_env()
  return setmetatable({}, { __index = _G })
end

---@return ReplContext
local function ensure_ctx()
  if not CurrCtx then
    CurrCtx = { env = new_env() }
  end
  return CurrCtx
end

function M.reset_current_ctx()
  if CurrCtx then
    CurrCtx.env = new_env()
  else
    CurrCtx = { env = new_env() }
  end
end

---@param lines string[]
---@return string[]
local function repl_impl(lines)
  local out = {}

  ---@param err string?
  local function on_error(err)
    table.insert(out, '[ERROR]')
    if err then
      table.insert(out, err)
    end
    local trace_back = debug.traceback()
    vim.list_extend(out, vim.split(trace_back, '\n', { plain = true }))
  end

  local function on_print(...)
    local str = table.concat(
      vim.tbl_map(function(v)
        return type(v) == 'string' and v or vim.inspect(v)
      end, { ... }),
      ' '
    )
    local output_lines = vim.split(str, '\n', { plain = true })
    vim.list_extend(out, output_lines)
  end

  local chunk, err = load(table.concat(lines, '\n'), 'main@repl')

  if not chunk then
    on_error(err)
    return out
  end

  local ctx = ensure_ctx()
  local env = ctx.env
  setfenv(chunk, env)
  env.print = on_print
  local results = { xpcall(chunk, on_error) }
  local ok = table.remove(results, 1)
  if ok then
    local vals = vim.tbl_map(vim.inspect, results)

    if #vals > 0 then
      local ret = '=> ' .. vals[1]

      local ret_lines = vim.split(ret, '\n', { plain = true })
      vim.list_extend(out, ret_lines)

      for i = 2, #vals do
        table.insert(out, ',')
        vim.list_extend(out, vim.split(vals[i], '\n', { plain = true }))
      end
    end
  end
  return out
end

---@param bufnr integer
---@param from  ReplSrcLoc
---@param to    ReplSrcLoc
---@return string[]|nil
local function get_lines(bufnr, from, to)
  local ok, ret =
    pcall(vim.api.nvim_buf_get_text, bufnr, from[1], from[2], to[1], to[2], {})
  if not ok then
    vim.notify(
      string.format(
        'Cannot get text of buffer %d, [%d:%d]-[%d:%d] because `%s`',
        bufnr,
        from[1],
        from[2],
        to[1],
        to[2],
        ret
      ),
      vim.log.levels.ERROR,
      { title = LOG_TITLE }
    )
    return
  end
  return ret
end

---@param bufnr integer
---@param from  ReplSrcLoc
---@param to    ReplSrcLoc
function M.exec(bufnr, from, to)
  local lines = get_lines(bufnr, from, to)
  if not lines then
    return
  end
  local out = repl_impl(lines)
  local line_to_insert = to[1]
  vim.api.nvim_buf_set_lines(
    bufnr,
    line_to_insert + 1,
    line_to_insert + 1,
    false,
    out
  )
end

---@param bufnr integer
---@param from  ReplSrcLoc
---@param to    ReplSrcLoc
--- Evaluate region.
---
--- The last line *MUST* be a Lua expression.
--- All preceding lines are treated as setup statements.
--- Similar to Emacs eval-last-sexp:
--- the last line is rewritten as `return <expr>`.
function M.eval(bufnr, from, to)
  local lines = get_lines(bufnr, from, to)
  if not lines then
    return
  end
  lines[#lines] = 'return ' .. lines[#lines]
  local out = repl_impl(lines)
  local line_to_insert = to[1]
  vim.api.nvim_buf_set_lines(
    bufnr,
    line_to_insert + 1,
    line_to_insert + 1,
    false,
    out
  )
end

-- Helper function to change the mode
local function change_mode(mode_key)
  -- Safely parse special codes like <ESC> or <C-\><C-n>
  local keys = vim.api.nvim_replace_termcodes(mode_key, true, false, true)

  -- Send keys to the editor, "n" flag executes them as normal characters
  vim.api.nvim_feedkeys(keys, 'n', false)
end

local function exec_wrapper(fn)
  local buf = vim.api.nvim_get_current_buf()
  local from = vim.api.nvim_buf_get_mark(buf, '<')
  local to = vim.api.nvim_buf_get_mark(buf, '>')
  from[1] = from[1] - 1
  to[1] = to[1] - 1
  to[2] = to[2] + 1
  fn(buf, from, to)
end

-- for keymap
local function visual_wrapper(fn)
  fn = fn or M.exec
  local mode = vim.fn.mode()
  if not (mode == 'v' or mode == 'V') then
    vim.notify(
      'Unsupported mode: should not start repl on modes except `vV`',
      vim.log.levels.ERROR,
      { title = LOG_TITLE }
    )
    return
  end
  -- HACK: switch to normal mode, wait a tick and read selected range
  change_mode '<esc>'
  vim.schedule(bind(exec_wrapper, fn))
end

function M.setup()
  vim.api.nvim_create_user_command('ReplExec', exec_wrapper, { range = true })
  vim.keymap.set(
    -- XXX: don't support visual block because cannot get exact range
    'v',
    '<leader>rr',
    bind(visual_wrapper, M.exec),
    { silent = true, desc = 'Exec selected code' }
  )

  vim.api.nvim_create_user_command('ReplExec', exec_wrapper, { range = true })
  vim.keymap.set(
    -- XXX: don't support visual block because cannot get exact range
    'v',
    '<leader>re',
    bind(visual_wrapper, M.eval),
    { silent = true, desc = 'Eval selected code' }
  )
end

return M

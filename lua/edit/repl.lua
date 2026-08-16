--------------------------------------------------------------------------------
-- Emacs style repl infrastructure
--------------------------------------------------------------------------------
local M = {}
local LOG_TITLE = 'Repl'
local log = require 'utils.logger'.new(LOG_TITLE)

local bind = require 'utils.fnx'.bind

---@alias ReplSrcLoc {[1]: integer, [2]: integer} 0 based range

local COMMENT_PREFIX = '-- '

---@param lines string[]
---@return string[]
local function repl_impl(lines)
  local out = {}

  ---@param err string?
  local function on_error(err)
    table.insert(out, COMMENT_PREFIX .. '[ERROR]')
    local trace_back = debug.traceback(err, 2)
    local trace_lines = vim.split(trace_back, '\n', { plain = true })
    for i = 1, #trace_lines do
      trace_lines[i] = COMMENT_PREFIX .. trace_lines[i]
    end
    vim.list_extend(out, trace_lines)
  end

  local function on_print(...)
    local str = table.concat(
      vim.tbl_map(function(v)
        return type(v) == 'string' and v or vim.inspect(v)
      end, { ... }),
      ' '
    )
    local output_lines = vim.split(str, '\n', { plain = true })
    for i = 1, #output_lines do
      output_lines[i] = COMMENT_PREFIX .. output_lines[i]
    end
    vim.list_extend(out, output_lines)
  end

  local env = setmetatable({ print = on_print }, { __index = _G })
  local chunk, err = load(table.concat(lines, '\n'), 'main@repl', 't', env)

  if not chunk then
    on_error(err)
    return out
  end

  local results = { xpcall(chunk, on_error) }
  local ok = table.remove(results, 1)
  if ok then
    local vals = vim.tbl_map(vim.inspect, results)

    if #vals > 0 then
      local ret = '=> ' .. table.concat(vals, ', ')
      local ret_lines = vim.split(ret, '\n', { plain = true })
      for j = 1, #ret_lines do
        ret_lines[j] = COMMENT_PREFIX .. ret_lines[j]
      end
      vim.list_extend(out, ret_lines)
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
    log.error(
      'Cannot get text of buffer %d, [%d:%d]-[%d:%d] because `%s`',
      bufnr,
      from[1],
      from[2],
      to[1],
      to[2],
      ret
    )
    return
  end
  return ret
end

---@param bufnr integer
---@param from  ReplSrcLoc
---@param to    ReplSrcLoc
--- Evaluate region.
---
--- If last line starts with '=', it will be treated as
--- a Lua expression. All preceding lines are treated
--- as setup statements.
---
--- Similar to Emacs eval-last-sexp:
--- the last line is rewritten as `return <expr>`.
function M.eval(bufnr, from, to)
  local lines = get_lines(bufnr, from, to)
  if not lines then
    return
  end
  lines[#lines] = string.gsub(lines[#lines], '^%s*=', 'return ')
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
  local mode = vim.fn.mode()
  if not (mode == 'v' or mode == 'V') then
    log.error 'Unsupported mode: should not start repl on modes except `vV`'
    return
  end
  -- HACK: switch to normal mode, wait a tick and read selected range
  change_mode '<esc>'
  vim.schedule(bind(exec_wrapper, fn))
end

function M.setup()
  vim.api.nvim_create_user_command(
    'ReplEval',
    bind(exec_wrapper, M.eval),
    { range = true }
  )
  vim.keymap.set(
    -- XXX: don't support visual block because cannot get exact range
    'v',
    '<leader>re',
    bind(visual_wrapper, M.eval),
    { silent = true, desc = 'Eval selected code' }
  )
end

return M

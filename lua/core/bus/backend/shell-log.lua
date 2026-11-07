--------------------------------------------------------------------------------
-- Openup a bottom view of shell output
--------------------------------------------------------------------------------
local M = {}
local LOG_TITLE = 'Shell Log'
local log = require 'utils.logger'.new(LOG_TITLE)

local Ansi = require 'utils.ansi'
local Render = require 'utils.render'
local bind = require 'utils.fnx'.bind

local _buf, _ns

---@return integer, integer
local function ensure_buf_ns()
  if not _buf or not vim.api.nvim_buf_is_valid(_buf) then
    _buf = vim.api.nvim_create_buf(false, true)
    vim.bo[_buf].buftype = 'nofile'
    vim.bo[_buf].filetype = 'shell-log'
    vim.bo[_buf].bufhidden = 'hide'
    vim.bo[_buf].modifiable = false
    vim.bo[_buf].swapfile = false
    vim.keymap.set('n', 'q', function()
      vim.cmd 'close'
    end, {
      buf = _buf,
      silent = true,
      desc = 'Quit buffer',
    })
  end
  if not _ns then
    _ns = vim.api.nvim_create_namespace 'ShellLogBufferNs'
  end
  return _buf, _ns
end

---@param buf integer
---@param fn function
local function protect_write(buf, fn)
  local modifiable = vim.bo[buf].modifiable
  vim.bo[buf].modifiable = true
  pcall(fn)
  vim.bo[buf].modifiable = modifiable
end

local win_id

---@param bufnr integer
local function ensure_win(bufnr)
  if not win_id or not vim.api.nvim_win_is_valid(win_id) then
    win_id = vim.api.nvim_open_win(
      bufnr,
      false,
      { split = 'below', win = -1, height = 10 }
    )
  end
  return win_id
end

function M.show_popup()
  local bufnr = ensure_buf_ns()
  local win = ensure_win(bufnr)
  local last_line = vim.api.nvim_buf_line_count(bufnr)
  vim.api.nvim_win_set_cursor(win, { last_line, 0 })
end

local _pending_line = ''

---@param str string
---@return string[]
local function ensure_lines(str)
  _pending_line = _pending_line .. str
  local lines = vim.split(_pending_line, '\n')
  _pending_line = lines[#lines]
  local ret = {}
  for i = 1, #lines - 1 do
    table.insert(ret, lines[i])
  end
  return ret
end

function M.setup()
  Bus.register_subscriber(
    'shell-log',
    {
      prefix = {
        'msg.show.shell_',
        'shell.log.',
      },
    },
    vim.log.levels.DEBUG,
    function(msg)
      local lines
      if vim.startswith(msg.tag, 'msg.show.shell_') then
        local content = msg.content
        local raw = ''
        for _, segment in ipairs(content) do
          raw = raw .. segment[2]
        end
        lines = ensure_lines(raw)
      elseif msg.tag == 'shell.log.append' then
        lines = msg.content
      end
      local str = table.concat(lines, '\n')
      str = Ansi.normalize(str)
      local ok, ret = Ansi.to_tuples(str)
      if not ok then
        log.error('Cannot convert string to tuples, beacuse %s', tostring(ret))
        return false
      end
      ---@diagnostic disable-next-line
      local layout = Render.calculate_layout(ret)
      local bufnr, ns = ensure_buf_ns()
      local base = vim.api.nvim_buf_line_count(bufnr)
      protect_write(bufnr, bind(Render.render_into, bufnr, ns, layout, base))
      return false
    end
  )

  vim.api.nvim_create_user_command('ShellLog', M.show_popup, {})
end

return M

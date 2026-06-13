--------------------------------------------------------------------------------
-- Openup a bottom view of shell output
--------------------------------------------------------------------------------
local M = {}

local buf

---@return integer
local function ensure_buf()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].filetype = 'log'
    vim.bo[buf].bufhidden = 'hide'
    vim.bo[buf].swapfile = false
    vim.keymap.set('n', 'q', function()
      vim.cmd 'close'
    end, {
      buf = buf,
      silent = true,
      desc = 'Quit buffer',
    })
  end
  return buf
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
  local bufnr = ensure_buf()
  local win = ensure_win(bufnr)
  local last_line = vim.api.nvim_buf_line_count(bufnr)
  vim.api.nvim_win_set_cursor(win, { last_line, 0 })
end

function M.setup()
  Bus.register_subscriber(
    'shell-log',
    {
      prefix = {
        'msg.show.shell_',
      },
    },
    vim.log.levels.DEBUG,
    function(msg)
      local content = msg.content
      local str = ''
      for _, segment in ipairs(content) do
        str = str .. segment[2]
      end
      local lines = vim.split(str, '\n', { plain = true, trimempty = false })
      local bufnr = ensure_buf()
      vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, lines)
      local win = ensure_win(bufnr)
      local last_line = vim.api.nvim_buf_line_count(bufnr)
      vim.api.nvim_win_set_cursor(win, { last_line, 0 })
      return false
    end
  )

  vim.api.nvim_create_user_command('ShellLog', M.show_popup, {})
end

return M

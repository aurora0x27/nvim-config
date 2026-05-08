--------------------------------------------------------------------------------
-- Float window -- Basic ui layer
--------------------------------------------------------------------------------
local M = {}

---@class WinOpt
---@field width number
---@field height number
---@field row number
---@field col number
---@field anchor? 'NW'|'NE'|'SW'|'SE'
---@field relative? 'editor'|'win'|'cursor'
---@field border? 'rounded'|'single'|'none'
---@field focusable? boolean
---@field focus_on_open? boolean
---@field zindex? integer
---@field ft? string
---@field wo? table<string, any>
---@field bo? table<string, any>
---@field title string|table|nil
---@field title_pos 'left'|'center'|'right'|nil
---@field footer string|table|nil
---@field footer_pos 'left'|'center'|'right'|nil
---@field keys table<string, string|function>|nil   -- { q = "close", ["<Esc>"] = fn }
---@field on_close fun(win: Win)|nil
---@field noautocmd boolean|nil

---@class Win
---@field buf integer
---@field win integer|nil
---@field opts WinOpt
---@field _augroup integer|nil
---@field _closed boolean
local Win = {}
Win.__index = Win

---@type WinOpt
local WINOPT_DEFAULT = {
  width = 0.6,
  height = 0.4,
  row = 0.5,
  col = 0.5,
  anchor = 'NW',
  relative = 'editor',
  border = 'rounded',
  focusable = true,
  focus_on_open = false,
  zindex = 50,
  ft = '',
  wo = { number = false },
  bo = {},
}

local function resolve_size(val, max)
  if type(val) == 'number' and val > 0 and val < 1 then
    return math.floor(val * max)
  end
  return val
end

local function resolve_pos(val, max_val, size)
  if type(val) ~= 'number' then
    return val
  end

  if val > 0 and val < 1 then
    return math.floor(val * (max_val - size))
  end

  if val < 0 and val > -1 then
    return math.floor((max_val - size) * (1 + val))
  end

  return val
end

M.resolve_size = resolve_size

M.resolve_pos = resolve_pos

function Win:_build_config()
  local columns = vim.o.columns
  local lines = vim.o.lines

  local w = resolve_size(self.opts.width, columns)
  local h = resolve_size(self.opts.height, lines)
  w = math.max(1, w)
  h = math.max(1, h)
  local r = resolve_pos(self.opts.row, lines, h)
  local c = resolve_pos(self.opts.col, columns, w)

  local cfg = {
    relative = self.opts.relative,
    width = w,
    height = h,
    row = r,
    col = c,
    anchor = self.opts.anchor,
    border = self.opts.border,
    focusable = self.opts.focusable,
    zindex = self.opts.zindex,
    noautocmd = self.opts.noautocmd or false,
  }

  if self.opts.title and vim.fn.has('nvim-0.9') == 1 then
    cfg.title = self.opts.title
    cfg.title_pos = self.opts.title_pos or 'center'
  end

  if self.opts.footer and vim.fn.has('nvim-0.10') == 1 then
    cfg.footer = self.opts.footer
    cfg.footer_pos = self.opts.footer_pos or 'center'
  end

  return cfg
end

function Win:_setup_keys()
  local keys = self.opts.keys
  if not keys then
    return
  end
  for key, action in pairs(keys) do
    local rhs
    if action == 'close' then
      rhs = function()
        self:close()
      end
    elseif type(action) == 'function' then
      rhs = action
    else
      rhs = action
    end
    vim.keymap.set('n', key, rhs, {
      buffer = self.buf,
      nowait = true,
      silent = true,
      desc = type(action) == 'string' and action or nil,
    })
  end
end

function Win:_setup_autocmds()
  local group = 'ModulesWin_' .. self.buf
  self._augroup = vim.api.nvim_create_augroup(group, { clear = true })

  vim.api.nvim_create_autocmd('WinClosed', {
    group = self._augroup,
    pattern = tostring(self.win),
    once = true,
    callback = function()
      self:_on_closed()
    end,
  })

  vim.api.nvim_create_autocmd('VimResized', {
    group = self._augroup,
    callback = function()
      if self.win and vim.api.nvim_win_is_valid(self.win) then
        vim.api.nvim_win_set_config(self.win, self:_build_config())
      end
    end,
  })
end

function Win:_on_closed()
  if self._closed then
    return
  end
  self._closed = true
  self.win = nil
  if self._augroup then
    pcall(vim.api.nvim_del_augroup_by_id, self._augroup)
    self._augroup = nil
  end
  if self.opts.on_close then
    self.opts.on_close(self)
  end
end

---@param lines? string[]
---@return Win
function Win:open(lines)
  if not self.buf or not vim.api.nvim_buf_is_valid(self.buf) then
    self.buf = vim.api.nvim_create_buf(false, true)
    self._closed = false
  end

  local bo = vim.tbl_extend('force', {
    buftype = 'nofile',
    bufhidden = 'wipe',
    swapfile = false,
  }, self.opts.bo or {})
  if self.opts.ft and self.opts.ft ~= '' then
    bo.filetype = self.opts.ft
  end
  for k, v in pairs(bo) do
    vim.bo[self.buf][k] = v
  end

  if lines then
    vim.bo[self.buf].modifiable = true
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
    vim.bo[self.buf].modifiable = false
  end

  local cfg = self:_build_config()
  if not self.win or not vim.api.nvim_win_is_valid(self.win) then
    self.win =
      vim.api.nvim_open_win(self.buf, self.opts.focus_on_open ~= false, cfg)
  else
    vim.api.nvim_win_set_config(self.win, cfg)
  end

  for k, v in pairs(self.opts.wo or {}) do
    vim.wo[self.win][k] = v
  end

  self:_setup_keys()
  self:_setup_autocmds()

  return self
end

---@return boolean
function Win:close()
  if self._closed then
    return false
  end
  if self.win and vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_close(self.win, true)
    return true
  end
  self:_on_closed()
  return false
end

function Win:focus()
  if self:is_valid() then
    vim.api.nvim_set_current_win(self.win)
  end
end

---@return boolean
function Win:is_valid()
  return self.win ~= nil and vim.api.nvim_win_is_valid(self.win)
end

---@param lines string[]
---@param start_line? integer
---@param end_line?  integer
function Win:set_lines(lines, start_line, end_line)
  vim.bo[self.buf].modifiable = true
  vim.api.nvim_buf_set_lines(
    self.buf,
    start_line or 0,
    end_line or -1,
    false,
    lines
  )
  vim.bo[self.buf].modifiable = false
  return self
end

---@param lines string|string[]
function Win:append(lines)
  if type(lines) == 'string' then
    lines = { lines }
  end
  local n = vim.api.nvim_buf_line_count(self.buf)
  vim.bo[self.buf].modifiable = true
  vim.api.nvim_buf_set_lines(self.buf, n, n, false, lines)
  vim.bo[self.buf].modifiable = false
  return self
end

function Win:scroll_bottom()
  if not self:is_valid() then
    return
  end
  local n = vim.api.nvim_buf_line_count(self.buf)
  vim.api.nvim_win_set_cursor(self.win, { n, 0 })
  return self
end

---@param title string|table
function Win:set_title(title)
  self.opts.title = title
  if self:is_valid() and vim.fn.has('nvim-0.9') == 1 then
    vim.api.nvim_win_set_config(self.win, {
      title = title,
      title_pos = self.opts.title_pos or 'center',
    })
  end
  return self
end

---@param footer string|table
function Win:set_footer(footer)
  self.opts.footer = footer
  if self:is_valid() and vim.fn.has('nvim-0.10') == 1 then
    vim.api.nvim_win_set_config(self.win, {
      footer = footer,
      footer_pos = self.opts.footer_pos or 'center',
    })
  end
  return self
end

---@param new_opts WinOpt
function Win:update(new_opts)
  self.opts = vim.tbl_extend('force', self.opts, new_opts)
  if self:is_valid() then
    vim.api.nvim_win_set_config(self.win, self:_build_config())
    for k, v in pairs(self.opts.wo or {}) do
      vim.wo[self.win][k] = v
    end
  end
  return self
end

---@param opts? WinOpt
---@return Win
function M.create(opts)
  return setmetatable({
    opts = vim.tbl_deep_extend('force', WINOPT_DEFAULT, opts or {}),
    _closed = false,
  }, Win)
end

---@param opts?  WinOpt
---@param lines? string[]
---@return Win
function M.open(opts, lines)
  return M.create(opts):open(lines)
end

return M

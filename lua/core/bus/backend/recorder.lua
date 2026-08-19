--------------------------------------------------------------------------------
-- Message Recorder
-- Record, browse, replay, and render Neovim messages.
--------------------------------------------------------------------------------

---@class MsgRecorderOpt
---@field max_msg_limit? integer

local M = {}

local RecordedMessages = {}
local MessagePreviewer = nil
local PREVIEW_TITLE = ' RecordedMsg '
local LOG_TITLE = 'Message Recorder'
local MESSAGES_BUF_NAMESPACE = 'messages_buffer'
local log = require 'utils.logger'.new(LOG_TITLE)

local Render = require 'utils.render'
local calculate_layout = Render.calculate_layout
local bind = require 'utils.fnx'.bind

local sprintf = string.format

---@type MsgRecorderOpt
local MSG_RECORDER_OPT_DEFAULT = {
  max_msg_limit = 1024,
}

local Opt = vim.deepcopy(MSG_RECORDER_OPT_DEFAULT)

local function make_previewer()
  local Previewer = require 'fzf-lua.previewer.builtin'

  if MessagePreviewer then
    return MessagePreviewer
  end

  local P = Previewer.buffer_or_file:extend()

  function P:new(o, opts, fzf_win)
    P.super.new(self, o, opts, fzf_win)
    self.title = PREVIEW_TITLE
    setmetatable(self, P)
    return self
  end

  function P:parse_entry(entry_str)
    local idx = tonumber(entry_str:match('^%[(%d+)%]'))
    local entry = RecordedMessages[idx]
    return entry
  end

  function P:populate_preview_buf(entry_str)
    local tmpbuf = self:get_tmp_buffer()
    local msg = self:parse_entry(entry_str)
    if not msg then
      return
    end
    if type(msg.content) == 'string' then
      local lines = vim.split(msg.content, '\n', { plain = true })
      vim.api.nvim_buf_set_lines(tmpbuf, 0, -1, false, lines)
    else
      local layout = calculate_layout(msg.content)
      vim.api.nvim_buf_set_lines(tmpbuf, 0, -1, false, layout.lines)
      local ns = vim.api.nvim_create_namespace('fzf_msg_preview')
      vim.api.nvim_buf_clear_namespace(tmpbuf, ns, 0, -1)
      for _, m in ipairs(layout.marks) do
        pcall(vim.api.nvim_buf_set_extmark, tmpbuf, ns, m.row, m.col_start, {
          end_col = m.col_end,
          hl_group = m.hl,
          priority = 100,
        })
      end
    end
    self:set_preview_buf(tmpbuf)
    self.win:update_preview_title(PREVIEW_TITLE)
    self.win:update_preview_scrollbar()
  end

  MessagePreviewer = P
  return MessagePreviewer
end

function M.fzf_messages()
  local Fzf = require 'fzf-lua'

  local contents = {}

  for i, msg in ipairs(RecordedMessages) do
    local time_str = os.date('%H:%M:%S', math.floor(msg.timestamp / 1000))

    local summary
    if type(msg.content) == 'string' then
      summary = vim.split(msg.content, '\n')[1]:sub(1, 80)
    else
      local layout = calculate_layout(msg.content)
      summary = layout.lines[1]:gsub('\n', ' '):sub(1, 80)
    end

    table.insert(
      contents,
      sprintf(
        '[%d] %s │ %-10s │ %s',
        i,
        time_str,
        msg.tag:gsub('msg.show.', ''),
        summary
      )
    )
  end

  contents = vim.fn.reverse(contents)

  Fzf.fzf_exec(contents, {
    prompt = '> ',
    previewer = make_previewer(),
    actions = {
      ['default'] = function(selected)
        local idx = tonumber(selected[1]:match('^%[(%d+)%]'))
        local msg = RecordedMessages[idx]
        if msg then
          -- reboardcast
          -- NOTE: Keep origin message immutable
          local snapshot = Bus.dup(msg, { no_record = true })
          Bus.emit_msg(snapshot)
        end
      end,
      ['ctrl-y'] = function(selected)
        local idx = tonumber(selected[1]:match('^%[(%d+)%]'))
        local msg = RecordedMessages[idx]
        if type(msg.content) == 'string' then
          vim.fn.setreg('+', msg.content)
        else
          local layout = calculate_layout(msg.content)
          vim.fn.setreg('+', table.concat(layout.lines, '\n'))
        end
        local newmsg = Bus.build_msg(
          'notify',
          vim.log.levels.INFO,
          'Copied to clipboard',
          { title = LOG_TITLE }
        )
        newmsg.meta.no_record = true
        Bus.emit_msg(newmsg)
      end,
    },
    winopts = {
      wrap = true,
      title = ' Messages ',
    },
    fzf_opts = {
      ['--delimiter'] = ' ',
      ['--with-nth'] = '2..',
      ['--tiebreak'] = 'index',
    },
  })
end

local MsgBuf
local MsgBufNs = vim.api.nvim_create_namespace(MESSAGES_BUF_NAMESPACE)

local TITLE_OF_LEVEL = {
  [vim.log.levels.TRACE] = 'Trace',
  [vim.log.levels.DEBUG] = 'Debug',
  [vim.log.levels.INFO] = 'Info',
  [vim.log.levels.WARN] = 'Warn',
  [vim.log.levels.ERROR] = 'Error',
}

---@param name string
---@param level? vim.log.levels
local function hl(name, level)
  return 'Recorder' .. name .. (TITLE_OF_LEVEL[level] or '')
end

local function make_messages_buf()
  local buf = vim.api.nvim_create_buf(false, true)
  local o = vim.bo[buf]
  o.buftype = 'nofile'
  o.filetype = 'messages'
  o.modifiable = false
  o.swapfile = false
  o.buflisted = false
  vim.keymap.set(
    'n',
    'q',
    vim.schedule_wrap(function()
      vim.cmd 'close'
    end),
    { buf = buf }
  )
  return buf
end

local function ensure_messages_buf()
  if not MsgBuf or not vim.api.nvim_buf_is_valid(MsgBuf) then
    MsgBuf = make_messages_buf()
  end
  return MsgBuf, MsgBufNs
end

---@param msg Message
---@return NvimMsgTuple[]
local function parse_msg(msg)
  local tuples = {}
  ---@param str      string
  ---@param hl_s     string
  ---@param attr_id? integer
  local function append_tuple(str, hl_s, attr_id)
    table.insert(
      tuples,
      { attr_id or 0, str, vim.api.nvim_get_hl_id_by_name(hl_s) }
    )
  end
  local function append_sep()
    table.insert(tuples, { 0, ' ', 0 })
  end
  local function append_empty_line()
    table.insert(tuples, Render.NEWLINE_CHUNK)
  end
  local time = os.date('%H:%M:%S', math.floor(msg.timestamp / 1000))--[[@as string]]
  append_tuple(time, hl('MessagesBufferDateTime'))
  append_sep()
  append_tuple(
    TITLE_OF_LEVEL[msg.level] or 'Info',
    hl('Title', msg.level or vim.log.levels.INFO)
  )
  append_sep()
  append_tuple(msg.data.title or 'Notify', hl('MessagesBufferTitle'))
  append_sep()
  if type(msg.content) == 'string' then
    local lines = vim.split(msg.content, '\n', { plain = true })
    for i = 1, #lines do
      append_tuple(lines[i], hl(''))
      if i ~= #lines then
        append_empty_line()
      end
    end
  else
    tuples = vim.list_extend(tuples, msg.content)
  end
  return tuples
end

local function modify_messages_buf(buf, fn)
  vim.bo[buf].modifiable = true
  local ok, err = pcall(fn)
  vim.bo[buf].modifiable = false

  if not ok then
    error(err)
  end
end

---@param msg Message
local function messages_buf_append_msg(msg)
  local buf, ns = ensure_messages_buf()
  local tuples = parse_msg(msg)
  local layout = calculate_layout(tuples)
  local line_count = vim.api.nvim_buf_line_count(buf)
  local base_row = line_count

  -- An empty buffer always has one empty line.
  if
    line_count == 1 and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ''
  then
    base_row = 0
    modify_messages_buf(
      buf,
      bind(vim.api.nvim_buf_set_lines, buf, 0, 1, false, layout.lines)
    )
  else
    modify_messages_buf(
      buf,
      bind(
        vim.api.nvim_buf_set_lines,
        buf,
        line_count,
        line_count,
        false,
        layout.lines
      )
    )
  end

  for _, mark in ipairs(layout.marks) do
    vim.api.nvim_buf_set_extmark(buf, ns, base_row + mark.row, mark.col_start, {
      end_row = base_row + mark.row,
      end_col = mark.col_end,
      hl_group = mark.hl,
    })
  end
end

function M.clear()
  log.info 'All the messages cleared'
  RecordedMessages = {}

  local buf, ns = ensure_messages_buf()
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  modify_messages_buf(
    buf,
    bind(vim.api.nvim_buf_set_lines, buf, 0, -1, false, {})
  )
end

-- TODO: vertical split
function M.view_messages_buffer()
  local buf = ensure_messages_buf()
  vim.api.nvim_open_win(
    buf,
    true,
    { split = 'below', height = 10, style = 'minimal' }
  )
end

local function handler(msg)
  if msg.tag == 'msg.clear' then
    M.clear()
    return false
  end
  if msg.tag == 'msg.history_show' then
    M.view_messages_buffer()
    return
  end
  if msg.meta.no_record then
    return false
  end
  if #RecordedMessages >= Opt.max_msg_limit then
    table.remove(RecordedMessages, 1)
  end
  table.insert(RecordedMessages, msg)
  messages_buf_append_msg(msg)
  return false
end

local function init_hl()
  local links = {
    [hl('MessagesBuffer')] = 'Normal',
    [hl('MessagesBufferTitle')] = 'Title',
    [hl('MessagesBufferDateTime')] = 'Special',
  }
  for lvl, Level in pairs(TITLE_OF_LEVEL) do
    local link = vim.tbl_contains({ 'Trace', 'Debug' }, Level) and 'NonText'
      or nil
    links[hl('', lvl)] = 'Normal'
    links[hl('Icon', lvl)] = link or ('DiagnosticSign' .. Level)
    links[hl('Border', lvl)] = link or ('Diagnostic' .. Level)
    links[hl('Title', lvl)] = link or ('Diagnostic' .. Level)
    links[hl('Footer', lvl)] = link or ('Diagnostic' .. Level)
  end
  for from, to in pairs(links) do
    vim.api.nvim_set_hl(0, from, { link = to })
  end
end

---@param opts? MsgRecorderOpt
function M.setup(opts)
  Opt = vim.tbl_deep_extend('force', Opt, opts or {})
  Bus.register_observer('recorder', handler)
  Bus.register_subscriber('recorder', {
    exact = {
      'notify',
      'msg.clear',
      'msg.show.emsg',
      'msg.show.echo',
      'msg.show.echoerr',
      'msg.show.echomsg',
      'msg.show.list_cmd',
      'msg.show.lua_error',
      'msg.show.lua_print',
      'msg.show.rpc_error',
      'msg.show.shell_out',
      'msg.show.shell_ret',
      'msg.show.shell_err',
      'msg.show.quickfix',
      'msg.show.wmsg',
      'msg.history_show',
    },
  }, vim.log.levels.TRACE, handler)
  init_hl()
  vim.api.nvim_create_user_command('MessageClear', M.clear, {})
  vim.api.nvim_create_user_command(
    'MessageBufferView',
    M.view_messages_buffer,
    {}
  )
  vim.keymap.set(
    'n',
    'g<',
    M.view_messages_buffer,
    { desc = 'View Messages Buffer', noremap = true, silent = true }
  )
end

return M

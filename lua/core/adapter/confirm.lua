--------------------------------------------------------------------------------
-- Confirm UI, only callbacks
--------------------------------------------------------------------------------
local Win = require 'core.ui.window'

local M = {}

---@type Win|nil
local confirm_win = nil
local ns_id = vim.api.nvim_create_namespace('ConfirmUIHighlights')

local hl_name_cache = {}

---@param hl_id integer
---@return string|nil
local function resolve_hl(hl_id)
  if hl_id == 0 then
    return nil
  end
  if hl_name_cache[hl_id] ~= nil then
    return hl_name_cache[hl_id] or nil
  end
  local name = vim.fn.synIDattr(hl_id, 'name')
  hl_name_cache[hl_id] = (name ~= '' and name) or false
  return hl_name_cache[hl_id] or nil
end

---@param chunks NvimMsgTuple[]
---@return ChunkLayout
local function layout_chunks(chunks)
  local lines = { '' }
  local marks = {}
  local row = 0

  for _, tuple in ipairs(chunks) do
    local text = tuple[2]
    local hl = resolve_hl(tuple[3])
    local segments = vim.split(text, '\n', { plain = true })

    for i, seg in ipairs(segments) do
      if i > 1 then
        row = row + 1
        table.insert(lines, '')
      end
      if seg ~= '' then
        local col_start = #lines[row + 1]
        lines[row + 1] = lines[row + 1] .. seg
        local col_end = #lines[row + 1]
        if hl then
          table.insert(marks, {
            row = row,
            col_start = col_start,
            col_end = col_end,
            hl = hl,
          })
        end
      end
    end
  end
  return { lines = lines, marks = marks }
end

---@param msg_show_data table
---@param content table
---@param pos integer
---@param firstc string
---@param prompt string
---@param indent integer
---@param level integer
---@diagnostic disable:unused-local
function M.on_cmdline_show(
  msg_show_data,
  content,
  pos,
  firstc,
  prompt,
  indent,
  level
)
  local all_chunks = {}
  vim.list_extend(all_chunks, msg_show_data.content or {})
  table.insert(all_chunks, { 0, '\n\n', 0 })

  if prompt and prompt ~= '' then
    table.insert(all_chunks, { 0, prompt, 63 })
  end
  vim.list_extend(all_chunks, content or {})

  local layout = layout_chunks(all_chunks)

  local max_w = 0
  for _, line in ipairs(layout.lines) do
    max_w = math.max(max_w, vim.fn.strdisplaywidth(line))
  end

  local win_opts = {
    width = math.min(max_w + 4, math.floor(vim.o.columns * 0.8)),
    height = #layout.lines,
    row = 0.15,
    col = 0.5,
    relative = 'editor',
    border = 'rounded',
    title = { { ' Confirm ', 'FloatTitle' } },
    title_pos = 'center',
    zindex = 250,
    focusable = false,
    wo = {
      winhighlight = 'FloatBorder:FloatBorder,NormalFloat:Normal',
    },
  }

  if confirm_win and confirm_win:is_valid() then
    confirm_win:update(win_opts)
  else
    confirm_win = Win.open(win_opts)
  end
  confirm_win:open(layout.lines)
  local buf = confirm_win.buf
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
  for _, m in ipairs(layout.marks) do
    pcall(vim.api.nvim_buf_set_extmark, buf, ns_id, m.row, m.col_start, {
      end_col = m.col_end,
      hl_group = m.hl,
      priority = 100,
    })
  end
  vim.cmd 'redraw'
end

---@param level integer
---@param abort boolean
---@diagnostic disable:unused-local
function M.on_cmdline_hide(level, abort)
  if confirm_win then
    confirm_win:close()
    confirm_win = nil
  end
end

return M

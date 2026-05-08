local M = {}

--- resolve hl_id to highlight group name, cached
---@type table<integer, string|false>
local hl_name_cache = {}

---@param hl_id integer
---@return string|nil
function M.resolve_hl(hl_id)
  if hl_id == 0 then
    return nil
  end
  local cached = hl_name_cache[hl_id]
  if cached ~= nil then
    return cached or nil
  end
  local name = vim.fn.synIDattr(hl_id, 'name')
  -- store false for empty to distinguish from uncached nil
  hl_name_cache[hl_id] = (name ~= '' and name) or false
  return hl_name_cache[hl_id] or nil
end

---@class ChunkLayout
---@field lines  string[]               plain text lines for notify
---@field marks  {row:integer, col_start:integer, col_end:integer, hl:string}[]

--- Convert NvimMsgChunk[] to plain lines + extmark specs
--- Handles \n splits within chunks correctly
---@param chunks NvimMsgTuple[]
---@return ChunkLayout
function M.calculate_layout(chunks)
  local lines = { '' }
  local marks = {}
  local row = 0

  for _, tuple in ipairs(chunks) do
    ---@type NvimMsgChunk
    local chunk = {
      attr_id = tuple[1],
      text = tuple[2],
      hl_id = tuple[3],
    }
    local hl = M.resolve_hl(chunk.hl_id)
    local text = chunk.text

    -- split on newlines, each segment may span a line boundary
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

---@param msg       string
---@param text_hl?  integer
---@param attr?     integer
function M.to_chunks(msg, text_hl, attr)
  return {
    { attr or 0, msg, text_hl or vim.api.nvim_get_hl_id_by_name('Normal') },
  }
end

M.NEWLINE_CHUNK = { 0, '\n', 0 }

return M

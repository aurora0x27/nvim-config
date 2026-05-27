--------------------------------------------------------------------------------
-- Display tabs and buffers
--------------------------------------------------------------------------------
local UIIcons = require 'assets.icons'.get('ui', true)
local Icons = {
  TruncLeft = UIIcons.Left,
  TruncRight = UIIcons.Right,
}
local Utils = require 'heirline.utils'
local BufferBlock = require 'core.ui.heirline.tabline.bufblk'
local TabBlock = require 'core.ui.heirline.tabline.tabblk'

--------------------------------------------------------------------------------
--- FOR TESTING
--------------------------------------------------------------------------------
-- this is the default function used to retrieve buffers
local get_bufs = function()
  return vim.tbl_filter(function(bufnr)
    return vim.api.nvim_get_option_value('buflisted', { buf = bufnr })
  end, vim.api.nvim_list_bufs())
end

-- initialize the buflist cache
local buflist_cache = {}
local AUG =
  vim.api.nvim_create_augroup('HeirlineBufferTabline', { clear = true })

vim.api.nvim_create_autocmd({ 'VimEnter', 'UIEnter', 'BufAdd', 'BufDelete' }, {
  group = AUG,
  callback = function()
    vim.schedule(function()
      local buffers = get_bufs()
      for i, v in ipairs(buffers) do
        buflist_cache[i] = v
      end
      for i = #buffers + 1, #buflist_cache do
        buflist_cache[i] = nil
      end
    end)
  end,
})
--------------------------------------------------------------------------------
--- FOR TESTING
--------------------------------------------------------------------------------

local Buffers = Utils.make_buflist({ BufferBlock }, {
  provider = Icons.TruncLeft,
  hl = { fg = 'overlay2' },
}, {
  provider = Icons.TruncRight,
  hl = { fg = 'overlay2' },
}, function()
  -- TODO: get buflist from buffer pool
  -- TESTING:
  return buflist_cache
end, false)

local Tabs = Utils.make_tablist(TabBlock)

local Tabline = {
  conditions = function()
    return vim.bo.filetype ~= 'alpha'
  end,
  --- Add an Offset component if use neo-tree
  Buffers,
  { provider = '│', hl = { fg = 'overlay2' } },
  { provider = '%=' },
  Tabs,
}

return Tabline

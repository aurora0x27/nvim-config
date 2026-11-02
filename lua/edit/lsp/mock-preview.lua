--------------------------------------------------------------------------------
--- Mocked preview window open function
--------------------------------------------------------------------------------
local M = {}

local api = vim.api
local lsp = vim.lsp

---@param winnr integer
---@return boolean `true` if `winnr` is a valid floating window
local function is_float(winnr)
  return api.nvim_win_is_valid(winnr) and vim.fn.win_gettype(winnr) == 'popup'
end

local function find_window_by_var(name, value)
  for _, win in ipairs(api.nvim_list_wins()) do
    if vim.w[win][name] == value then
      return win
    end
  end
end

--- Closes the preview window
---
---@param winnr integer window id of preview window
---@param bufnrs table? optional list of ignored buffers
local function close_preview_window(winnr, bufnrs)
  vim.schedule(function()
    -- exit if we are in one of ignored buffers
    if bufnrs and vim.list_contains(bufnrs, api.nvim_get_current_buf()) then
      return
    end

    local augroup = 'nvim.preview_window_' .. winnr
    pcall(api.nvim_del_augroup_by_name, augroup)

    -- Preview window was converted to a normal window (e.g. |CTRL-W_H|):
    -- keep it open and stop managing it.
    if api.nvim_win_is_valid(winnr) and not is_float(winnr) then
      local srcbuf = vim.w[winnr].lsp_floating_bufnr
      if
        srcbuf
        and api.nvim_buf_is_valid(srcbuf)
        and vim.b[srcbuf].lsp_floating_preview == winnr
      then
        vim.b[srcbuf].lsp_floating_preview = nil
      end
      return
    end

    pcall(api.nvim_win_close, winnr, true)
  end)
end

--- Creates autocommands to close a preview window when events happen.
---
---@param events table list of events
---@param winnr integer window id of preview window
---@param floating_bufnr integer floating preview buffer
---@param bufnr integer buffer that opened the floating preview buffer
---@see autocmd-events
local function close_preview_autocmd(events, winnr, floating_bufnr, bufnr)
  local augroup = api.nvim_create_augroup('nvim.preview_window_' .. winnr, {
    clear = true,
  })

  -- close the preview window when entered a buffer that is not
  -- the floating window buffer or the buffer that spawned it
  api.nvim_create_autocmd('BufLeave', {
    group = augroup,
    buf = bufnr,
    callback = function()
      vim.schedule(function()
        -- When jumping to the quickfix window from the preview window,
        -- do not close the preview window.
        if api.nvim_get_option_value('filetype', { buf = 0 }) ~= 'qf' then
          close_preview_window(winnr, { floating_bufnr, bufnr })
        end
      end)
    end,
  })

  if #events > 0 then
    api.nvim_create_autocmd(events, {
      group = augroup,
      buf = bufnr,
      callback = function()
        close_preview_window(winnr)
      end,
    })
  end
end

--- Shows contents in a floating window.
---
---@param contents table of lines to show in window
---@param syntax string of syntax to set for opened buffer
---@param opts? vim.lsp.util.open_floating_preview.Opts with optional fields
--- (additional keys are filtered with |vim.lsp.util.make_floating_popup_options()|
--- before they are passed on to |nvim_open_win()|)
---@return integer bufnr of newly created float window
---@return integer winid of newly created float window preview window
function M.open_floating_preview(contents, syntax, opts)
  vim.validate('contents', contents, 'table')
  vim.validate('syntax', syntax, 'string', true)
  vim.validate('opts', opts, 'table', true)
  opts = opts or {}
  opts.wrap = opts.wrap ~= false -- wrapping by default
  opts.focus = opts.focus ~= false
  opts.close_events = opts.close_events
    or { 'CursorMoved', 'CursorMovedI', 'InsertCharPre' }

  local bufnr = api.nvim_get_current_buf()

  local floating_winnr = opts._update_win

  -- Create/get the buffer
  local floating_bufnr --- @type integer
  if floating_winnr then
    floating_bufnr = api.nvim_win_get_buf(floating_winnr)
  else
    -- check if this popup is focusable and we need to focus
    if opts.focus_id and opts.focusable ~= false and opts.focus then
      -- Go back to previous window if we are in a focusable one
      local current_winnr = api.nvim_get_current_win()
      if vim.w[current_winnr][opts.focus_id] and is_float(current_winnr) then
        api.nvim_command('wincmd p')
        return bufnr, current_winnr
      end
      do
        local win = find_window_by_var(opts.focus_id, bufnr)
        if win and is_float(win) and vim.fn.pumvisible() == 0 then
          -- focus and return the existing buf, win
          api.nvim_set_current_win(win)
          api.nvim_command('stopinsert')
          return api.nvim_win_get_buf(win), win
        end
      end
    end

    -- check if another floating preview already exists for this buffer
    -- and close it if needed
    local existing_float = vim.b[bufnr].lsp_floating_preview
    if existing_float and is_float(existing_float) then
      api.nvim_win_close(existing_float, true)
    end
    floating_bufnr = api.nvim_create_buf(false, true)
  end

  -- Set up the contents, using treesitter for markdown
  local do_stylize = syntax == 'markdown' and vim.g.syntax_on ~= nil

  if do_stylize then
    local width = lsp.util._make_floating_popup_size(contents, opts)
    contents = lsp.util._normalize_markdown(contents, { width = width })
  else
    -- Clean up input: trim empty lines
    contents =
      vim.split(table.concat(contents, '\n'), '\n', { trimempty = true })

    if syntax then
      vim.bo[floating_bufnr].syntax = syntax
    end
  end

  vim.bo[floating_bufnr].modifiable = true
  api.nvim_buf_set_lines(floating_bufnr, 0, -1, false, contents)

  if floating_winnr then
    api.nvim_win_set_config(floating_winnr, {
      border = opts.border,
      title = opts.title,
    })
  else
    -- Compute size of float needed to show (wrapped) lines
    if opts.wrap then
      opts.wrap_at = opts.wrap_at or api.nvim_win_get_width(0)
    else
      opts.wrap_at = nil
    end

    -- TODO(lewis6991): These function assume the current window to determine options,
    -- therefore it won't work for opts._update_win and the current window if the floating
    -- window
    local width, height = lsp.util._make_floating_popup_size(contents, opts)
    local float_option =
      lsp.util.make_floating_popup_options(width, height, opts)

    floating_winnr = api.nvim_open_win(floating_bufnr, false, float_option)

    api.nvim_buf_set_keymap(
      floating_bufnr,
      'n',
      'q',
      '<cmd>bdelete<cr>',
      { silent = true, noremap = true, nowait = true }
    )
    close_preview_autocmd(
      opts.close_events,
      floating_winnr,
      floating_bufnr,
      bufnr
    )

    -- save focus_id
    if opts.focus_id then
      api.nvim_win_set_var(floating_winnr, opts.focus_id, bufnr)
    end
    api.nvim_buf_set_var(bufnr, 'lsp_floating_preview', floating_winnr)
    api.nvim_win_set_var(floating_winnr, 'lsp_floating_bufnr', bufnr)
  end

  api.nvim_create_autocmd('WinClosed', {
    group = api.nvim_create_augroup(
      'nvim.closing_floating_preview',
      { clear = true }
    ),
    callback = function(args)
      local winid = vim._tointeger(args.match)
      local preview_bufnr = vim.w[winid].lsp_floating_bufnr
      if
        preview_bufnr
        and api.nvim_buf_is_valid(preview_bufnr)
        and winid == vim.b[preview_bufnr].lsp_floating_preview
      then
        vim.b[bufnr].lsp_floating_preview = nil
        return true
      end
    end,
  })

  vim.wo[floating_winnr].foldenable = false -- Disable folding.
  vim.wo[floating_winnr].wrap = opts.wrap -- Soft wrapping.
  vim.wo[floating_winnr].linebreak = true -- Break lines a bit nicer
  vim.wo[floating_winnr].breakindent = true -- Slightly better list presentation.
  vim.wo[floating_winnr].smoothscroll = true -- Scroll by screen-line instead of buffer-line.
  vim.wo[floating_winnr].winfixbuf = true -- Disable buffer switching.

  vim.bo[floating_bufnr].modifiable = false
  vim.bo[floating_bufnr].bufhidden = 'wipe'

  if do_stylize then
    vim.wo[floating_winnr].conceallevel = 0
    vim.wo[floating_winnr].concealcursor = ''
    vim.bo[floating_bufnr].filetype = 'markdown'
    vim.treesitter.start(floating_bufnr)
    if not opts.height then
      -- Reduce window height if TS highlighter conceals code block backticks.
      local win_height = api.nvim_win_get_height(floating_winnr)
      local text_height = api.nvim_win_text_height(
        floating_winnr,
        { max_height = win_height }
      ).all
      if text_height < win_height then
        api.nvim_win_set_height(floating_winnr, text_height)
      end
    end
  end

  return floating_bufnr, floating_winnr
end
return M

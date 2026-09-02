--------------------------------------------------------------------------------
-- Lsp module
--------------------------------------------------------------------------------
local M = {}

local lsp = vim.lsp
local api = vim.api
local methods = lsp.protocol.Methods
local thunk = require 'utils.fnx'.thunk
local bind = require 'utils.fnx'.bind
local AUG = api.nvim_create_augroup('lsp-module', { clear = true })
local BORDER = require 'assets.theme'.border
local LOG_TITLE = 'LSP Module'
local log = require 'utils.logger'.new(LOG_TITLE)

local lsp_list = Lang.get_lsp_enable_list()

local Opts = {
  enable_inlay_hint = Profile.enable_inlay_hint,
}

--------------------------------------------------------------------------------
-- Override lsp.hover
--------------------------------------------------------------------------------
local hover_impl = lsp.buf.hover
local signature_help_impl = lsp.buf.signature_help

--------------------------------------------------------------------------------
-- LspAttach callback
--------------------------------------------------------------------------------
local function on_attach(event)
  local bufnr = event.buf
  local map = vim.keymap.set

  ----------------------------------------------------------------------------
  -- Misc
  ----------------------------------------------------------------------------

  map('n', '<leader>lr', lsp.buf.rename, {
    desc = 'LSP [R]ename Symbol',
    noremap = true,
    silent = true,
    buffer = bufnr,
  })

  local client = vim.lsp.get_client_by_id(event.data.client_id)
  local has_inlay_hint = client
    and client:supports_method('textDocument/inlayHint', bufnr)
  if has_inlay_hint and Opts.enable_inlay_hint then
    lsp.inlay_hint.enable(true, { bufnr = event.buf })
  end
  map('n', '<leader>lh', function()
    if not has_inlay_hint then
      log.warn('Buffer id = %d does not have capability of `inlayHint`', bufnr)
      return
    end
    local stat = lsp.inlay_hint.is_enabled { bufnr = bufnr }
    log.info('Lsp Inlay Hints ' .. (stat and 'Disabled' or 'Enabled'))
    lsp.inlay_hint.enable(not stat, { bufnr = bufnr })
  end, { buffer = bufnr, desc = 'Toggle Inlay [H]ints' })

  map({ 'n', 'v' }, '<leader>la', thunk('fzf-lua', 'lsp_code_actions'), {
    desc = '[L]ist Code [A]ctions',
    noremap = true,
    silent = true,
    buffer = bufnr,
  })

  ---@param prefix string
  ---@param suffix string
  ---@param callee string
  ---@param desc string
  ---@param opts? table
  local function mux_map(prefix, suffix, callee, desc, opts)
    opts = vim.tbl_deep_extend('force', { with_leader = false }, opts or {})
    local comb = prefix .. suffix
    map(
      'n',
      '<leader>tn' .. comb,
      bind(thunk('fzf-lua', callee), {
        jump1 = false,
        actions = {
          ['default'] = thunk('fzf-lua.actions', 'file_tabedit'),
        },
      }),
      {
        desc = desc .. ' with [N]ew [T]ab',
        noremap = true,
        silent = true,
      }
    )
    map(
      'n',
      '<leader>ws' .. comb,
      bind(thunk('fzf-lua', callee), {
        jump1 = false,
        actions = {
          ['default'] = thunk('fzf-lua.actions', 'file_split'),
        },
      }),
      {
        desc = '[W]indow [S]plit ' .. desc,
        noremap = true,
        silent = true,
      }
    )
    map(
      'n',
      '<leader>wv' .. comb,
      bind(thunk('fzf-lua', callee), {
        jump1 = false,
        actions = {
          ['default'] = thunk('fzf-lua.actions', 'file_vsplit'),
        },
      }),
      {
        desc = '[W]indow [V]split ' .. desc,
        noremap = true,
        silent = true,
      }
    )
    if opts.with_leader then
      prefix = '<leader>' .. prefix
    end
    local FzfLspPeekCfg = { jump1 = false }
    local FzfLspGotoCfg = { jump1 = true }
    map('n', prefix .. suffix, bind(thunk('fzf-lua', callee), FzfLspGotoCfg), {
      desc = desc,
      noremap = true,
      silent = true,
      buffer = bufnr,
    })
    map(
      'n',
      prefix .. 'p' .. suffix,
      bind(thunk('fzf-lua', callee), FzfLspPeekCfg),
      {
        desc = desc,
        noremap = true,
        silent = true,
        buffer = bufnr,
      }
    )
  end

  mux_map('g', 'd', 'lsp_definitions', '[D]efinition')
  mux_map('g', 'D', 'lsp_declarations', '[D]eclarations')
  mux_map(
    'l',
    'i',
    'lsp_incoming_calls',
    '[I]ncoming Calls',
    { with_leader = true }
  )
  mux_map(
    'l',
    'o',
    'lsp_outgoing_calls',
    '[O]utgoing Calls',
    { with_leader = true }
  )
  mux_map('l', 's', 'lsp_type_sub', '[S]ub Types', { with_leader = true })
  mux_map('l', 'S', 'lsp_type_super', '[S]uper Types', { with_leader = true })

  map('n', '<leader>fr', thunk('fzf-lua', 'lsp_references'), {
    desc = '[R]eferences',
    noremap = true,
    silent = true,
    buffer = bufnr,
  })

  map('n', '<leader>fs', thunk('fzf-lua', 'lsp_document_symbols'), {
    desc = 'Document [S]ymbols',
    noremap = true,
    silent = true,
    buffer = bufnr,
  })

  map('n', '<leader>fS', thunk('fzf-lua', 'lsp_live_workspace_symbols'), {
    desc = 'Workspace [S]ymbols',
    noremap = true,
    silent = true,
    buffer = bufnr,
  })
end

--------------------------------------------------------------------------------
-- Lsp buf startup
--------------------------------------------------------------------------------
local function validate_cmd(v)
  if type(v) == 'table' then
    if vim.fn.executable(v[1]) == 0 then
      return false, v[1] .. ' is not executable'
    end
    return true
  end
  return type(v) == 'function'
end

--- @param config vim.lsp.Config
local function validate_config(config)
  vim.validate(
    'cmd',
    config.cmd,
    validate_cmd,
    'expected function or table with executable command'
  )
  vim.validate('reuse_client', config.reuse_client, 'function', true)
  vim.validate('filetypes', config.filetypes, 'table', true)
end

--- Returns true if:
--- 1. the config is managed by vim.lsp,
--- 2. it applies to the given buffer, and
--- 3. its config is valid (in particular: its `cmd` isn't broken).
---
--- @param bufnr integer
--- @param config vim.lsp.Config
--- @param logging boolean
local function can_start(bufnr, config, logging)
  assert(config)
  if
    type(config.filetypes) == 'table'
    and not vim.tbl_contains(config.filetypes, vim.bo[bufnr].filetype)
  then
    return false
  end

  local config_ok, err = pcall(validate_config, config)
  if not config_ok then
    if logging then
      M.error(('invalid "%s" config: %s'):format(config.name, err))
    end
    return false
  end

  return true
end

--- @param bufnr integer
--- @param config vim.lsp.Config
local function start_config(bufnr, config)
  return vim.lsp.start(config, {
    bufnr = bufnr,
    reuse_client = config.reuse_client,
    _root_markers = config.root_markers,
  })
end

--- @param bufnr integer
local function lsp_buf_startup(bufnr)
  -- Only ever attach to buffers that represent an actual file.
  if vim.bo[bufnr].buftype ~= '' then
    return
  end

  -- Stop any clients that no longer apply to this buffer.
  local clients = lsp.get_clients { bufnr = bufnr, _uninitialized = true }
  for _, client in ipairs(clients) do
    -- Don't index into lsp.config[…] unless is_enabled() is true.
    if
      lsp.is_enabled(client.name)
      -- Check that the client is managed by vim.lsp.config before deciding to detach it!
      and lsp.config[client.name]
      and not can_start(bufnr, lsp.config[client.name], false)
    then
      lsp.buf_detach_client(bufnr, client.id)
    end
  end

  -- Start any clients that apply to this buffer.
  for name in vim.spairs(lsp._enabled_configs) do
    local config = lsp.config[name]
    if config and can_start(bufnr, config, true) then
      M.info('Started LSP: [' .. name .. ']', { title = 'Info' })

      -- Deepcopy config so changes done in the client
      -- do not propagate back to the enabled configs.
      config = vim.deepcopy(config)

      if type(config.root_dir) == 'function' then
        ---@param root_dir string
        config.root_dir(bufnr, function(root_dir)
          config.root_dir = root_dir
          vim.schedule(function()
            start_config(bufnr, config)
          end)
        end)
      else
        start_config(bufnr, config)
      end
    end
  end
end
--------------------------------------------------------------------------------
--- Lsp buf startup
--------------------------------------------------------------------------------
local function init_usercmd()
  api.nvim_create_autocmd('LspAttach', {
    group = AUG,
    callback = on_attach,
  })

  api.nvim_create_user_command('LspInfo', function()
    local clients = lsp.get_clients()
    if #clients == 0 then
      print 'No active LSP clients.'
      return
    end

    for _, client in ipairs(clients) do
      print(
        string.format(
          'Client ID: %d | Name: %s | Attached Buffers: %s',
          client.id,
          client.name,
          vim.inspect(client.attached_buffers)
        )
      )
    end
  end, {})

  api.nvim_create_user_command(
    'LspStatus',
    '<cmd>checkhealth lsp<CR>',
    { desc = 'Alias to checkhealth lsp' }
  )

  api.nvim_create_user_command('LspLog', function()
    vim.cmd(string.format('tabnew %s', lsp.log.get_filename()))
  end, {
    desc = 'Opens the Nlsp client log.',
  })

  api.nvim_create_user_command('LspStart', function(info)
    local servers = info.fargs
    if #servers == 0 then
      local bufnr = vim.api.nvim_get_current_buf()
      lsp_buf_startup(bufnr)
    end
    lsp.enable(servers)
  end, {
    desc = 'Enable and launch a language server',
    nargs = '?',
    complete = function()
      return lsp_list
    end,
  })

  api.nvim_create_user_command('LspStop', function(info)
    local clients = lsp.get_clients()
    local clients_to_stop = info.fargs
    if #clients_to_stop == 0 then
      for _, client in ipairs(clients) do
        client:stop()
        print('Stopped LSP: [' .. client.name .. ']')
      end
    else
      for _, client in ipairs(clients) do
        if vim.tbl_contains(clients_to_stop, client.name) then
          client:stop(true)
          print('Stopped LSP: [' .. client.name .. ']')
        end
      end
    end
  end, {
    desc = 'Disable active language servers',
    nargs = '*',
    complete = function()
      local names = {}
      for _, client in ipairs(lsp.get_clients()) do
        table.insert(names, client.name)
      end
      return names
    end,
  })

  api.nvim_create_user_command('LspRestart', function()
    local bufnr = api.nvim_get_current_buf()
    for _, client in ipairs(lsp.get_clients { bufnr = bufnr }) do
      local config = client.config
      client:stop(true)
      vim.defer_fn(function()
        lsp.start(config)
        print('Restarted LSP: [' .. client.name .. ']')
      end, 100)
    end
  end, {})
end

--------------------------------------------------------------------------------
--- Preview window open
--------------------------------------------------------------------------------
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
local function open_floating_preview(contents, syntax, opts)
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
        api.nvim_win_resize(floating_winnr, -1, text_height)
      end
    end
  end

  return floating_bufnr, floating_winnr
end
--------------------------------------------------------------------------------
--- Preview window open
--------------------------------------------------------------------------------

local function mock_handlers()
  lsp.buf.hover = bind(hover_impl, {
    border = BORDER,
    focus_id = methods.textDocument_hover,
    max_width = 80,
    max_height = 20,
  })

  lsp.buf.signature_help = bind(signature_help_impl, {
    border = BORDER,
    focus_id = methods.textDocument_signatureHelp,
    max_width = 80,
    max_height = 20,
  })

  -- TODO: Remove this override once open_floating_preview is replaced
  -- by the new generic floating-window API (see neovim/neovim#25514).
  --
  -- The stock implementation hardcodes conceallevel=2 for Markdown
  -- previews, which causes cursor-dependent layout changes in hover
  -- windows. Keep conceallevel=0 until the replacement API allows this
  -- presentation behavior to be controlled.
  lsp.util.open_floating_preview = open_floating_preview
end

local is_setup = false

function M.setup()
  if is_setup then
    return
  end

  for _, name in ipairs(lsp_list) do
    lsp.enable(name)
  end

  -- setup lsp progress animation
  require 'edit.lsp.progress'.setup()
  init_usercmd()
  mock_handlers()

  is_setup = true
end

return M

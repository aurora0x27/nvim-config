--------------------------------------------------------------------------------
-- Lsp module
--------------------------------------------------------------------------------
local M = {}

local lsp = vim.lsp
local api = vim.api
local methods = lsp.protocol.Methods
local thunk = require 'utils.loader'.thunk
local bind = require 'utils.loader'.bind
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

local is_setup = false

function M.setup()
  if is_setup then
    return
  end

  for _, name in ipairs(lsp_list) do
    lsp.enable(name)
  end

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

  -- setup lsp progress animation
  require 'edit.lsp.progress'.setup()

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

  is_setup = true
end

return M

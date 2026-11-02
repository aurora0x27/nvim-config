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
local sprintf = string.format

local lsp_list = Lang.get_lsp_enable_list()

local Opts = {
  enable_inlay_hint = Profile.enable_inlay_hint,
}

--------------------------------------------------------------------------------
-- Override lsp.hover
--------------------------------------------------------------------------------
local hover_impl = lsp.buf.hover
local signature_help_impl = lsp.buf.signature_help

---@class LspConfigSummary
---@field name string
---@field enabled boolean
---@field active integer
---
---@class LspClientsSummary
---@field id integer
---@field name string
---@field root string?
---@field initialized boolean
---@field stopping boolean
---@field buffers integer[]
---@field buffer_labels table<integer, string>

---@class LspInfoSummary
---@field configs LspConfigSummary[]
---@field clients LspClientsSummary[]

---@param bufnr integer
---@return string
local function buffer_label(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  return name ~= '' and vim.fn.fnamemodify(name, ':~:.')
    or sprintf('[No Name:%d]', bufnr)
end

---@return LspInfoSummary
function M.info()
  local configs = {}

  local ok, resolved = pcall(vim.lsp.get_configs)
  if not ok then
    log.error('Cannot resolve LSP configs: %s', resolved)
    resolved = {}
  end

  for _, cfg in ipairs(resolved) do
    configs[#configs + 1] = {
      name = cfg.name,
      enabled = vim.lsp.is_enabled(cfg.name),
      active = #vim.lsp.get_clients({ name = cfg.name, _uninitialized = true }),
    }
  end

  local clients = {}
  for _, client in ipairs(vim.lsp.get_clients({ _uninitialized = true })) do
    local bufs = {}
    local labels = {}
    for bufnr in pairs(client.attached_buffers or {}) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        bufs[#bufs + 1] = bufnr
        labels[bufnr] = buffer_label(bufnr)
      end
    end
    clients[#clients + 1] = {
      id = client.id,
      name = client.name,
      initialized = client.initialized,
      stopping = client:is_stopped(),
      root = type(client.config.root_dir) == 'string'
          and client.config.root_dir
        or nil,
      buffers = bufs,
      buffer_labels = labels,
    }
  end

  return { configs = configs, clients = clients }
end

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
        buf = bufnr,
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
        buf = bufnr,
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
        buf = bufnr,
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
      buf = bufnr,
    })
    map(
      'n',
      prefix .. 'p' .. suffix,
      bind(thunk('fzf-lua', callee), FzfLspPeekCfg),
      {
        desc = desc,
        noremap = true,
        silent = true,
        buf = bufnr,
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
    buf = bufnr,
  })

  map('n', '<leader>fs', thunk('fzf-lua', 'lsp_document_symbols'), {
    desc = 'Document [S]ymbols',
    noremap = true,
    silent = true,
    buf = bufnr,
  })

  map('n', '<leader>fS', thunk('fzf-lua', 'lsp_live_workspace_symbols'), {
    desc = 'Workspace [S]ymbols',
    noremap = true,
    silent = true,
    buf = bufnr,
  })
end

local function init_autocmd()
  api.nvim_create_autocmd('LspAttach', {
    group = AUG,
    callback = on_attach,
  })
end

---@param arglead string
---@return string[]
local function complete_client_names(arglead)
  local seen = {}
  local names = {}

  for _, client in ipairs(lsp.get_clients({ _uninitialized = true })) do
    local name = client.name
    if not seen[name] and vim.startswith(name, arglead) then
      seen[name] = true
      names[#names + 1] = name
    end
  end

  table.sort(names)
  return names
end

---@param arglead string
---@return string[]
local function complete_config_names(arglead)
  local seen = {}
  local names = {}

  local ok, configs = pcall(lsp.get_configs)
  if not ok then
    -- Fall back to the configured enable-list if resolving every config
    -- fails because of one broken user config.
    for _, name in ipairs(lsp_list) do
      if vim.startswith(name, arglead) then
        names[#names + 1] = name
      end
    end
    table.sort(names)
    return names
  end

  for _, cfg in ipairs(configs) do
    local name = cfg.name
    if name and not seen[name] and vim.startswith(name, arglead) then
      seen[name] = true
      names[#names + 1] = name
    end
  end

  table.sort(names)
  return names
end

---@param filetype string
---@return string[]
local function enabled_configs_for(filetype)
  local names = {}

  local ok, configs = pcall(lsp.get_configs, { enabled = true })
  if not ok then
    log.error('Cannot resolve enabled LSP configs: %s', configs)
    return names
  end

  for _, cfg in ipairs(configs) do
    if cfg.filetypes == nil or vim.tbl_contains(cfg.filetypes, filetype) then
      names[#names + 1] = cfg.name
    end
  end

  table.sort(names)
  return names
end

---Detach a client from all buffers it is still attached to.
---@param client vim.lsp.Client
local function detach_client(client)
  for bufnr in pairs(client.attached_buffers or {}) do
    if api.nvim_buf_is_valid(bufnr) then
      pcall(lsp.buf_detach_client, bufnr, client.id)
    end
  end
end

local STOP_GRACEFUL_MS = 2000
local STOP_WAIT_MS = 2500
local STOP_FORCE_WAIT_MS = 500

---@param ids integer[]
---@param timeout integer
---@return boolean
local function wait_clients_gone(ids, timeout)
  return vim.wait(timeout, function()
    for _, id in ipairs(ids) do
      if lsp.get_client_by_id(id) ~= nil then
        return false
      end
    end
    return true
  end, 20)
end

local function init_usercmd()
  api.nvim_create_user_command('LspInfo', function()
    local info = M.info()
    local enabled_config_section = 'Configs:\n'
    for _, config in ipairs(info.configs) do
      enabled_config_section = enabled_config_section
        .. sprintf(
          '  %s %s clients: %d\n',
          config.name,
          config.enabled and '[enabled]' or '[disabled]',
          config.active
        )
    end
    local active_clients_section = 'Active clients:\n'
    for _, client in ipairs(info.clients) do
      local current_client_text = sprintf('  [%d] %s\n', client.id, client.name)
      current_client_text = current_client_text
        .. sprintf(
          '    initialized: %s\n',
          client.initialized and 'true' or 'false'
        )
      current_client_text = current_client_text
        .. sprintf('    root: %s\n', client.root or '[nil]')
      current_client_text = current_client_text
        .. sprintf('    stopping: %s\n', client.stopping and 'true' or 'false')
      current_client_text = current_client_text .. sprintf('    buffers:\n')
      for _, buf in ipairs(client.buffers) do
        current_client_text = current_client_text
          .. sprintf('      %d(%s)\n', buf, client.buffer_labels[buf])
      end
      active_clients_section = active_clients_section .. current_client_text
    end
    print(enabled_config_section .. '\n' .. active_clients_section)
  end, {})

  api.nvim_create_user_command(
    'LspStatus',
    '<cmd>checkhealth lsp<CR>',
    { desc = 'Alias to checkhealth lsp' }
  )

  api.nvim_create_user_command('LspLog', function()
    vim.cmd(sprintf('tabnew %s', lsp.log.get_filename()))
  end, {
    desc = 'Opens the Nlsp client log.',
  })

  api.nvim_create_user_command('LspStart', function(info)
    local names = info.fargs

    if #names == 0 then
      names = enabled_configs_for(vim.bo.filetype)
    end

    if #names == 0 then
      log.warn('No enabled LSP config for filetype `%s`', vim.bo.filetype)
      return
    end

    for _, name in ipairs(names) do
      local ok, err = pcall(lsp.enable, name)
      if not ok then
        log.error('Cannot start LSP `%s`: %s', name, err)
      end
    end
  end, {
    desc = 'Start enabled LSP configs for current buffer',
    nargs = '*',
    complete = function(arglead)
      return complete_config_names(arglead)
    end,
  })

  api.nvim_create_user_command('LspStop', function(info)
    local clients = {}
    local seen = {}

    if #info.fargs == 0 then
      clients = lsp.get_clients({ _uninitialized = true })
    else
      for _, name in ipairs(info.fargs) do
        for _, client in
          ipairs(lsp.get_clients({ name = name, _uninitialized = true }))
        do
          if not seen[client.id] then
            seen[client.id] = true
            clients[#clients + 1] = client
          end
        end
      end
    end

    if #clients == 0 then
      log.info('No LSP clients to stop')
      return
    end

    local ids = {}
    for _, client in ipairs(clients) do
      ids[#ids + 1] = client.id

      if client:is_stopped() then
        -- The process is already exiting but its buffer attachments may
        -- still be around. Clean them up before waiting for the client
        -- to be removed from the registry.
        detach_client(client)
      else
        client:stop(info.bang and true or STOP_GRACEFUL_MS)
      end
    end

    if not wait_clients_gone(ids, STOP_WAIT_MS) then
      -- The graceful shutdown timed out. Detach whatever is left and
      -- force-stop the remaining clients.
      for _, client in ipairs(clients) do
        if lsp.get_client_by_id(client.id) ~= nil then
          detach_client(client)
          -- Force-stop even if the client already has `_is_stopping` set:
          -- a server which ignores `shutdown` may still hold the RPC open.
          client:stop(true)
        end
      end
      wait_clients_gone(ids, STOP_FORCE_WAIT_MS)
    end

    for _, client in ipairs(clients) do
      if lsp.get_client_by_id(client.id) ~= nil then
        log.warn('LSP client [%s] is still running', client.name)
      else
        log.info('Stopped LSP: [%s]', client.name)
      end
    end
  end, {
    nargs = '*',
    bang = true,
    desc = 'Stop and cleanup LSP clients',
    complete = function(arglead)
      return complete_client_names(arglead)
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
  end, { desc = 'Restart lsp of current buffer' })
end

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
  lsp.util.open_floating_preview =
    require 'edit.lsp.mock-preview'.open_floating_preview
end

local _initialized = false

function M.setup()
  if _initialized then
    log.error 'Should not initialize module twice'
    return
  end

  -- Register handlers before enabling configs so that clients which start
  -- during setup do not miss LspAttach / LspProgress.
  init_autocmd()
  require 'edit.lsp.progress'.setup()
  init_usercmd()
  mock_handlers()

  lsp.enable(lsp_list)

  _initialized = true
end

return M

--------------------------------------------------------------------------------
-- Lsp module
--------------------------------------------------------------------------------
local M = {}

local lsp = vim.lsp
local api = vim.api
local methods = lsp.protocol.Methods
local misc = require 'utils.misc'
local thunk = require 'utils.loader'.thunk
local bind = require 'utils.loader'.bind
local AUG = api.nvim_create_augroup('lsp-module', { clear = true })

local lsp_list = Lang.get_lsp_enable_list()

local Opts = {
    enable_inlay_hint = Profile.enable_inlay_hint,
}

local LOG_TITLE = 'LSP Module'

--------------------------------------------------------------------------------
-- Override lsp.hover
--------------------------------------------------------------------------------
local hover_impl = lsp.buf.hover

local function lsp_buf_setup(event)
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
            misc.warn(
                string.format(
                    'Buffer id = %d does not have capability of `inlayHint`',
                    bufnr
                ),
                { title = LOG_TITLE }
            )
            return
        end
        local stat = lsp.inlay_hint.is_enabled { bufnr = bufnr }
        misc.info(
            'Lsp Inlay Hints ' .. (stat and 'Disabled' or 'Enabled'),
            { title = LOG_TITLE }
        )
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
        map(
            'n',
            prefix .. suffix,
            bind(thunk('fzf-lua', callee), FzfLspGotoCfg),
            {
                desc = desc,
                noremap = true,
                silent = true,
                buffer = bufnr,
            }
        )
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

local is_setup = false

function M.setup()
    if not Profile.enable_lsp or is_setup then
        return
    end

    for _, name in ipairs(lsp_list) do
        lsp.enable(name)
    end

    lsp.buf.hover = bind(hover_impl, {
        border = 'rounded',
        focus_id = methods.textDocument_hover,
        max_width = 80,
        max_height = 20,
    })

    -- setup lsp progress animation
    require 'edit.lsp.progress'.setup()

    api.nvim_create_autocmd('LspAttach', {
        group = AUG,
        callback = lsp_buf_setup,
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
            misc.lsp_buf_startup(bufnr)
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

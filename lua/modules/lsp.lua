--------------------------------------------------------------------------------
-- Lsp module
--------------------------------------------------------------------------------
local M = {}

local lsp = vim.lsp
local api = vim.api
local util = lsp.util
local methods = lsp.protocol.Methods
local hover_ns = api.nvim_create_namespace 'hover'
local misc = require 'utils.misc'

local lsp_list = require('modules.lang').get_lsp_enable_list()

--------------------------------------------------------------------------------
-- Override lsp.hover
--------------------------------------------------------------------------------
local hover = function(config)
    config = config or {}
    config.border = config.border or 'rounded'
    config.focus_id = methods.textDocument_hover
    config.max_width = config.max_width or 80
    config.max_height = config.max_height or 20

    lsp.buf_request_all(0, methods.textDocument_hover, function(client)
        ---@diagnostic disable:param-type-mismatch
        return util.make_position_params(nil, client.offset_encoding)
    end, function(results, ctx)
        local bufnr = assert(ctx.bufnr)
        if api.nvim_get_current_buf() ~= bufnr then
            return
        end

        local results1 = {}
        for client_id, resp in pairs(results) do
            local err, result = resp.err, resp.result
            if err then
                lsp.log.error(err.code, err.message)
            elseif result then
                results1[client_id] = result
            end
        end

        if vim.tbl_isempty(results1) then
            if config.silent ~= true then
                misc.info('No information available', { title = 'Lsp Hover' })
            end
            return
        end

        local contents = {}
        local nresults = #vim.tbl_keys(results1)
        local format = 'markdown'

        for client_id, result in pairs(results1) do
            local client = assert(lsp.get_client_by_id(client_id))
            if nresults > 1 then
                contents[#contents + 1] = string.format('# %s', client.name)
            end

            if
                type(result.contents) == 'table'
                and result.contents.kind == 'plaintext'
            then
                if #results1 == 1 then
                    format = 'plaintext'
                    contents = vim.split(
                        result.contents.value or '',
                        '\n',
                        { trimempty = true }
                    )
                else
                    contents[#contents + 1] = '```'
                    vim.list_extend(
                        contents,
                        vim.split(
                            result.contents.value or '',
                            '\n',
                            { trimempty = true }
                        )
                    )
                    contents[#contents + 1] = '```'
                end
            else
                vim.list_extend(
                    contents,
                    util.convert_input_to_markdown_lines(result.contents)
                )
            end

            if result.range then
                local start = result.range.start
                local end_ = result.range['end']
                local start_idx = util._get_line_byte_from_position(
                    bufnr,
                    start,
                    client.offset_encoding
                )
                local end_idx = util._get_line_byte_from_position(
                    bufnr,
                    end_,
                    client.offset_encoding
                )
                vim.hl.range(
                    bufnr,
                    hover_ns,
                    'LspReferenceTarget',
                    { start.line, start_idx },
                    { end_.line, end_idx },
                    {
                        priority = vim.hl.priorities.user,
                    }
                )
            end

            contents[#contents + 1] = '---'
        end
        contents[#contents] = nil

        if vim.tbl_isempty(contents) then
            if config.silent ~= true then
                misc.info('No information available', { title = 'Lsp Hover' })
            end
            return
        end

        local _, winid = util.open_floating_preview(contents, format, config)

        api.nvim_create_autocmd('WinClosed', {
            pattern = tostring(winid),
            once = true,
            callback = function()
                api.nvim_buf_clear_namespace(bufnr, hover_ns, 0, -1)
            end,
        })
    end)
end

local function lsp_buf_setup(event)
    local bufnr = event.buf
    local thunk = require('utils.loader').thunk
    local bind = require('utils.loader').bind
    local map = vim.keymap.set

    --------------------------------------------------------------------------------
    -- Misc
    --------------------------------------------------------------------------------

    map('n', '<leader>lr', lsp.buf.rename, {
        desc = 'LSP [R]ename Symbol',
        noremap = true,
        silent = true,
        buffer = bufnr,
    })

    map('n', '<leader>lh', function()
        local stat = lsp.inlay_hint.is_enabled { bufnr = bufnr }
        misc.info('Lsp Inlay Hints ' .. (stat and 'Disabled' or 'Enabled'))
        lsp.inlay_hint.enable(not stat, { bufnr = bufnr })
    end, { buffer = bufnr, desc = 'Toggle Inlay [H]ints' })

    map('n', '<leader>la', thunk('fzf-lua', 'lsp_code_actions'), {
        desc = '[L]ist Code [A]ctions',
        noremap = true,
        silent = true,
        buffer = bufnr,
    })

    --------------------------------------------------------------------------------
    -- Peek
    --------------------------------------------------------------------------------

    local FzfLspPeekCfg = { jump1 = false }

    map(
        'n',
        'gpd',
        bind(thunk('fzf-lua', 'lsp_definitions'), FzfLspPeekCfg),
        { desc = '[P]eek [D]efinition' }
    )

    map(
        'n',
        'gpr',
        bind(thunk('fzf-lua', 'lsp_references'), FzfLspPeekCfg),
        { desc = '[P]eek [R]eference' }
    )

    map(
        'n',
        'gpi',
        bind(thunk('fzf-lua', 'lsp_implementations'), FzfLspPeekCfg),
        {
            desc = '[P]eek Symbol [I]mplementation',
            noremap = true,
            silent = true,
            buffer = bufnr,
        }
    )

    map(
        'n',
        'gpso',
        bind(thunk('fzf-lua', 'lsp_outgoing_calls'), FzfLspPeekCfg),
        {
            desc = '[P]eek [O]utgoing Calls',
            noremap = true,
            silent = true,
            buffer = bufnr,
        }
    )

    map(
        'n',
        'gpsi',
        bind(thunk('fzf-lua', 'lsp_incoming_calls'), FzfLspPeekCfg),
        {
            desc = '[P]eek [I]ncoming Calls',
            noremap = true,
            silent = true,
            buffer = bufnr,
        }
    )

    map('n', 'gpsS', bind(thunk('fzf-lua', 'lsp_type_super'), FzfLspPeekCfg), {
        desc = '[P]eek [S]uper Types',
        noremap = true,
        silent = true,
        buffer = bufnr,
    })

    map('n', 'gpss', bind(thunk('fzf-lua', 'lsp_type_sub'), FzfLspPeekCfg), {
        desc = 'FzfLua [P]eek [S]ub Types',
        noremap = true,
        silent = true,
        buffer = bufnr,
    })

    --------------------------------------------------------------------------------
    -- Goto
    --------------------------------------------------------------------------------

    local FzfLspGotoCfg = { jump1 = true }

    map('n', 'gd', bind(thunk('fzf-lua', 'lsp_definitions'), FzfLspGotoCfg), {
        desc = 'LSP [G]oto [D]efinition',
        noremap = true,
        silent = true,
        buffer = bufnr,
    })

    map('n', 'gD', bind(thunk('fzf-lua', 'lsp_declarations'), FzfLspGotoCfg), {
        desc = 'LSP [G]oto [D]eclaration',
        noremap = true,
        silent = true,
        buffer = bufnr,
    })

    map(
        'n',
        '<leader>lso',
        bind(thunk('fzf-lua', 'lsp_outgoing_calls'), FzfLspGotoCfg),
        {
            desc = 'FzfLua [L]ist [O]utgoing Calls',
            noremap = true,
            silent = true,
            buffer = bufnr,
        }
    )

    map(
        'n',
        '<leader>lsi',
        bind(thunk('fzf-lua', 'lsp_incoming_calls'), FzfLspGotoCfg),
        {
            desc = 'FzfLua [L]ist [I]ncoming Calls',
            noremap = true,
            silent = true,
            buffer = bufnr,
        }
    )

    map(
        'n',
        '<leader>lsS',
        bind(thunk('fzf-lua', 'lsp_type_super'), FzfLspGotoCfg),
        {
            desc = '[L]ist [S]uper Types',
            noremap = true,
            silent = true,
            buffer = bufnr,
        }
    )

    map(
        'n',
        '<leader>lss',
        bind(thunk('fzf-lua', 'lsp_type_sub'), FzfLspGotoCfg),
        {
            desc = '[L]ist [S]ub Types',
            noremap = true,
            silent = true,
            buffer = bufnr,
        }
    )

    map(
        'n',
        '<leader>fr',
        bind(thunk('fzf-lua', 'lsp_references'), FzfLspGotoCfg),
        {
            desc = '[F]ind Symbol [R]eferences',
            noremap = true,
            silent = true,
            buffer = bufnr,
        }
    )

    map('n', '<leader>fi', thunk('fzf-lua', 'lsp_implementations'), {
        desc = '[F]ind Symbol [I]mplementation',
        noremap = true,
        silent = true,
        buffer = bufnr,
    })

    map('n', '<leader>fs', thunk('fzf-lua', 'lsp_document_symbols'), {
        desc = '[F]ind Document [S]ymbols',
        noremap = true,
        silent = true,
        buffer = bufnr,
    })

    map('n', '<leader>fS', thunk('fzf-lua', 'lsp_live_workspace_symbols'), {
        desc = '[F]ind Workspace [S]ymbols',
        noremap = true,
        silent = true,
        buffer = bufnr,
    })
end

function M.setup()
    for _, name in ipairs(lsp_list) do
        lsp.enable(name)
    end

    lsp.buf.hover = hover

    api.nvim_create_autocmd('LspAttach', {
        group = api.nvim_create_augroup('lsp-attach', { clear = true }),
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
        vim.cmd(string.format('tabnew %s', lsp.get_log_path()))
    end, {
        desc = 'Opens the Nlsp client log.',
    })

    api.nvim_create_user_command('LspStart', function(info)
        local servers = info.fargs
        if #servers == 0 then
            local bufnr = vim.api.nvim_get_current_buf()
            require('utils.misc').lsp_buf_startup(bufnr)
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

return M

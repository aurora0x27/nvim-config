local LspConfig = {}

local lsp = vim.lsp
local api = vim.api
local util = lsp.util
local methods = lsp.protocol.Methods
local hover_ns = api.nvim_create_namespace 'hover'
local log = require 'utils.tools'

local lsp_list = {
    'lua_ls',
    'clangd',
    'rust_analyzer',
    'pyright',
    'neocmake',
    'gopls',
    'jdtls',
    'tinymist',
    -- 'clice',
}

-- override lsp.hover
local hover = function(config)
    config = config or {}
    config.border = config.border or 'rounded'
    config.focus_id = methods.textDocument_hover

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
                log.info('No information available', { title = 'Lsp Hover' })
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

            if type(result.contents) == 'table' and result.contents.kind == 'plaintext' then
                if #results1 == 1 then
                    format = 'plaintext'
                    contents = vim.split(result.contents.value or '', '\n', { trimempty = true })
                else
                    contents[#contents + 1] = '```'
                    vim.list_extend(contents, vim.split(result.contents.value or '', '\n', { trimempty = true }))
                    contents[#contents + 1] = '```'
                end
            else
                vim.list_extend(contents, util.convert_input_to_markdown_lines(result.contents))
            end

            if result.range then
                local start = result.range.start
                local end_ = result.range['end']
                local start_idx = util._get_line_byte_from_position(bufnr, start, client.offset_encoding)
                local end_idx = util._get_line_byte_from_position(bufnr, end_, client.offset_encoding)
                vim.hl.range(bufnr, hover_ns, 'LspReferenceTarget', { start.line, start_idx }, { end_.line, end_idx }, {
                    priority = vim.hl.priorities.user,
                })
            end

            contents[#contents + 1] = '---'
        end
        contents[#contents] = nil

        if vim.tbl_isempty(contents) then
            if config.silent ~= true then
                log.info('No information available', { title = 'Lsp Hover' })
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

function LspConfig.apply()
    if vim.g.enable_xmake_ls then
        table.insert(lsp_list, 'xmake_ls')
    end
    for _, name in ipairs(lsp_list) do
        lsp.enable(name)
    end

    lsp.buf.hover = hover

    api.nvim_create_autocmd('LspAttach', {
        group = api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
            local bufnr = event.buf
            local select = require('utils.loader').select

            vim.keymap.set(
                'n',
                'gd',
                select('fzf-lua', 'lsp_definitions'),
                { desc = 'LSP Goto Definition', noremap = true, silent = true, buffer = bufnr }
            )

            vim.keymap.set(
                'n',
                'gD',
                lsp.buf.declaration,
                { desc = 'LSP Goto Declaration', noremap = true, silent = true, buffer = bufnr }
            )

            vim.keymap.set(
                'n',
                '<leader>lr',
                lsp.buf.rename,
                { desc = 'LSP [R]ename Symbol', noremap = true, silent = true, buffer = bufnr }
            )

            vim.keymap.set('n', '<leader>lh', function()
                lsp.inlay_hint.enable(not lsp.inlay_hint.is_enabled { bufnr = bufnr }, { bufnr = bufnr })
            end, { buffer = bufnr, desc = 'Toggle Inlay [H]ints' })

            vim.keymap.set(
                'n',
                '<Leader>lso',
                select('fzf-lua', 'lsp_outgoing_calls'),
                { desc = 'FzfLua [L]ist [O]utgoing Calls', noremap = true, silent = true, buffer = bufnr }
            )

            vim.keymap.set(
                'n',
                '<Leader>lsi',
                select('fzf-lua', 'lsp_incoming_calls'),
                { desc = 'FzfLua [L]ist [I]ncoming Calls', noremap = true, silent = true, buffer = bufnr }
            )

            vim.keymap.set(
                'n',
                '<Leader>lsS',
                select('fzf-lua', 'lsp_type_super'),
                { desc = 'FzfLua [L]ist [S]uper Types', noremap = true, silent = true, buffer = bufnr }
            )

            vim.keymap.set(
                'n',
                '<Leader>lss',
                select('fzf-lua', 'lsp_type_sub'),
                { desc = 'FzfLua [L]ist [S]ub Types', noremap = true, silent = true, buffer = bufnr }
            )

            vim.keymap.set(
                'n',
                '<Leader>la',
                select('fzf-lua', 'lsp_code_actions'),
                { desc = 'FzfLua [L]ist Code [A]ctions', noremap = true, silent = true, buffer = bufnr }
            )

            vim.keymap.set(
                'n',
                '<Leader>fr',
                select('fzf-lua', 'lsp_references'),
                { desc = 'FzfLua Find Symbol [R]eferences', noremap = true, silent = true, buffer = bufnr }
            )

            vim.keymap.set(
                'n',
                '<Leader>fs',
                select('fzf-lua', 'lsp_document_symbols'),
                { desc = 'FzfLua Find Document [S]ymbols', noremap = true, silent = true, buffer = bufnr }
            )

            vim.keymap.set(
                'n',
                '<Leader>fS',
                select('fzf-lua', 'lsp_live_workspace_symbols'),
                { desc = 'FzfLua Find Workspace [S]ymbols', noremap = true, silent = true, buffer = bufnr }
            )
        end,
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

    api.nvim_create_user_command('LspStatus', ':checkhealth lsp', { desc = 'Alias to checkhealth lsp' })

    api.nvim_create_user_command('LspLog', function()
        vim.cmd(string.format('tabnew %s', lsp.get_log_path()))
    end, {
        desc = 'Opens the Nlsp client log.',
    })

    api.nvim_create_user_command('LspStart', function(info)
        local servers = info.fargs
        if #servers == 0 then
            local ft = vim.bo.filetype
            ---@diagnostic disable:undefined-field
            ---@diagnostic disable:invisible
            for name, _ in pairs(lsp.config._configs) do
                local fts = lsp.config[name].filetypes
                if fts and vim.tbl_contains(fts, ft) then
                    table.insert(servers, name)
                    print('Started LSP: [' .. name .. ']')
                end
            end
        end
        lsp.enable(servers)
    end, {
        desc = 'Enable and launch a language server',
        nargs = '?',
        complete = function()
            return lsp_list
        end,
    })

    api.nvim_create_user_command('LspStop', function()
        local bufnr = api.nvim_get_current_buf()
        for _, client in ipairs(lsp.get_clients { bufnr = bufnr }) do
            client:stop(true)
            print('Stopped LSP: [' .. client.name .. ']')
        end
    end, {})

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

return LspConfig

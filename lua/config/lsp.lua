local LspConfig = {}

local lsp = vim.lsp
local api = vim.api
local util = lsp.util
local ms = vim.lsp.protocol.Methods
local hover_ns = api.nvim_create_namespace 'hover'

local function make_position_params()
    if vim.fn.has 'nvim-0.11' == 1 then
        return function(client)
            return vim.lsp.util.make_position_params(nil, client.offset_encoding)
        end
    else
        ---@diagnostic disable-next-line: missing-parameter
        return vim.lsp.util.make_position_params()
    end
end

-- override vim.lsp.hover
local hover = function(config)
    config = config or {}
    config.border = config.border or 'rounded'
    config.focus_id = ms.textDocument_hover

    local params = make_position_params()
    lsp.buf_request_all(0, ms.textDocument_hover, params, function(results, ctx)
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
                vim.notify 'No information available'
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
                vim.notify 'No information available'
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
    local lsp_list = {
        'lua_ls',
        'clangd',
        'rust_analyzer',
        'pyright',
        'neocmake',
        'jdtls',
        -- 'clice',
    }

    for _, name in ipairs(lsp_list) do
        vim.lsp.enable(name)
    end

    vim.lsp.buf.hover = hover

    vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
            ---@diagnostic disable: unused-local
            local client = vim.lsp.get_client_by_id(event.data.client_id)
            local bufnr = event.buf
            vim.keymap.set(
                'n',
                'gd',
                vim.lsp.buf.definition,
                { desc = 'LSP Goto Definition', noremap = true, silent = true }
            )
            vim.keymap.set(
                'n',
                'gD',
                vim.lsp.buf.declaration,
                { desc = 'LSP Goto Declaration', noremap = true, silent = true }
            )
            vim.keymap.set(
                'n',
                '<leader>lr',
                vim.lsp.buf.rename,
                { desc = 'LSP Rename Symbol', noremap = true, silent = true }
            )
            vim.keymap.set('n', '<leader>lh', function()
                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }, { bufnr = bufnr })
            end, { buffer = bufnr, desc = 'Toggle inlay hints' })
        end,
    })

    vim.api.nvim_create_user_command('LspInfo', function()
        local clients = vim.lsp.get_clients()
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

    vim.api.nvim_create_user_command('LspStatus', ':checkhealth vim.lsp', { desc = 'Alias to checkhealth lsp' })

    vim.api.nvim_create_user_command('LspLog', function()
        vim.cmd(string.format('tabnew %s', vim.lsp.get_log_path()))
    end, {
        desc = 'Opens the Nvim LSP client log.',
    })

    vim.api.nvim_create_user_command('LspStart', function(info)
        local servers = info.fargs
        if #servers == 0 then
            local ft = vim.bo.filetype
            ---@diagnostic disable:invisible
            for name, _ in pairs(vim.lsp.config._configs) do
                local fts = vim.lsp.config[name].filetypes
                if fts and vim.tbl_contains(fts, ft) then
                    table.insert(servers, name)
                    print('Started LSP: [' .. name .. ']')
                end
            end
        end
        vim.lsp.enable(servers)
    end, {
        desc = 'Enable and launch a language server',
        nargs = '?',
        complete = function()
            return lsp_list
        end,
    })

    vim.api.nvim_create_user_command('LspStop', function()
        local bufnr = vim.api.nvim_get_current_buf()
        for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
            ---@diagnostic disable-next-line: param-type-mismatch
            client.stop(true)
            print('Stopped LSP: [' .. client.name .. ']')
        end
    end, {})

    vim.api.nvim_create_user_command('LspRestart', function()
        local bufnr = vim.api.nvim_get_current_buf()
        for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
            local config = client.config
            ---@diagnostic disable-next-line: param-type-mismatch
            client.stop(true)
            vim.defer_fn(function()
                vim.lsp.start(config)
                print('Restarted LSP: [' .. client.name .. ']')
            end, 100)
        end
    end, {})
end

return LspConfig

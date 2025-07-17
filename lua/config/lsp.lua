local LspConfig = {}

function LspConfig.apply()
    local lsp_list = {
        'lua_ls',
        'clangd',
        'rust_analyzer',
        'pyright',
        -- 'clice',
    }

    for _, name in ipairs(lsp_list) do
        vim.lsp.enable(name)
    end

    vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
            ---@diagnostic disable: unused-local
            local client = vim.lsp.get_client_by_id(event.data.client_id)
            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'LSP Goto Definition', noremap = true, silent = true })
            vim.keymap.set('n', 'gD', vim.lsp.buf.definition, { desc = 'LSP Goto Declaration', noremap = true, silent = true })
            vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, { desc = 'LSP Rename Symbol', noremap = true, silent = true })
        end,
    })

    vim.api.nvim_create_user_command('LspInfo', function()
        local clients = vim.lsp.get_clients()
        if #clients == 0 then
            print 'No active LSP clients.'
            return
        end

        for _, client in ipairs(clients) do
            print(string.format('Client ID: %d | Name: %s | Attached Buffers: %s', client.id, client.name, vim.inspect(client.attached_buffers)))
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

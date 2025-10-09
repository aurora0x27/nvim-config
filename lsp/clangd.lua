-- Clangd for c/cpp dev

local function switch_source_header(bufnr)
    local method_name = 'textDocument/switchSourceHeader'
    local client = vim.lsp.get_clients({ bufnr = bufnr, name = 'clangd' })[1]
    if not client then
        return vim.notify(
            ('method %s is not supported by any servers active on the current buffer'):format(method_name)
        )
    end
    local params = vim.lsp.util.make_text_document_params(bufnr)
    ---@diagnostic disable-next-line: param-type-mismatch
    client.request(method_name, params, function(err, result)
        if err then
            error(tostring(err))
        end
        if not result then
            vim.notify 'corresponding file cannot be determined'
            return
        end
        vim.cmd.edit(vim.uri_to_fname(result))
    end, bufnr)
end

local function symbol_info()
    local bufnr = vim.api.nvim_get_current_buf()
    local clangd_client = vim.lsp.get_clients({ bufnr = bufnr, name = 'clangd' })[1]
    ---@diagnostic disable-next-line: param-type-mismatch, missing-parameter
    if not clangd_client or not clangd_client.supports_method 'textDocument/symbolInfo' then
        return vim.notify('Clangd client not found', vim.log.levels.ERROR)
    end
    local win = vim.api.nvim_get_current_win()
    local params = vim.lsp.util.make_position_params(win, clangd_client.offset_encoding)
    ---@diagnostic disable-next-line: param-type-mismatch
    clangd_client.request('textDocument/symbolInfo', params, function(err, res)
        if err or #res == 0 then
            -- Clangd always returns an error, there is not reason to parse it
            return
        end
        local container = string.format('container: %s', res[1].containerName) ---@type string
        local name = string.format('name: %s', res[1].name) ---@type string
        vim.lsp.util.open_floating_preview({ name, container }, '', {
            height = 2,
            width = math.max(string.len(name), string.len(container)),
            focusable = false,
            focus = false,
            border = 'single',
            title = 'Symbol Info',
        })
        ---@diagnostic disable-next-line: param-type-mismatch
    end, bufnr)
end

local clangd = {
    filetypes = { 'c', 'cpp' },
    root_markers = {
        '.git/',
        'clice.toml',
        '.clang-tidy',
        '.clang-format',
        'compile_commands.json',
        'compile_flags.txt',
        'configure.ac', -- AutoTools
    },

    cmd = {
        'clangd',
        '--background-index',
        '--clang-tidy',
        '--header-insertion=iwyu',
        '--completion-style=detailed',
        '--function-arg-placeholders=true',
        '-j=4',
        '--fallback-style="{BasedOnStyle: LLVM, IndentWidth: 4}"',
    },

    capabilities = {
        textDocument = {
            completion = {
                editsNearCursor = true,
                completionItem = { snippetSupport = false },
            },
        },
        offsetEncoding = { 'utf-8', 'utf-16' },
    },
    reuse_client = function(client, config)
        return client.name == config.name
    end,
    settings = {
        clangd = {
            Completion = {
                CodePatterns = 'NONE',
            },
        },
    },

    ---@class ClangdInitializeResult: lsp.InitializeResult
    ---@field offsetEncoding? string

    ---@param init_result ClangdInitializeResult
    on_init = function(client, init_result)
        if init_result.offsetEncoding then
            client.offset_encoding = init_result.offsetEncoding
        end
    end,

    on_attach = function(_, buf)
        vim.api.nvim_buf_create_user_command(buf, 'LspClangdSwitchSourceHeader', function()
            switch_source_header(buf)
        end, { desc = 'Switch between source/header' })

        vim.api.nvim_buf_create_user_command(buf, 'LspClangdSymbolInfo', function()
            symbol_info()
        end, { desc = 'Show symbol info' })
    end,
}

return clangd

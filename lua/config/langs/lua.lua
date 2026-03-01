---@type LangSpec
return {
    treesitter = 'lua',
    formatter = { name = 'stylua' },
    lsp = require('modules.profile').use_emmylua_ls and { name = 'emmylua_ls', source = 'sys' }
        or { name = 'lua_ls', packname = 'lua-language-server' },
    plugins = 'lazydev',
}

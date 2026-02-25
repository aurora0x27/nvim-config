-- Regex highlighter

-- if true then return {} end   -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local TSEnsureInstalled = require('modules.lang').get_ts_install_list()

local function safe_ts_start(buf)
    local ft = vim.bo[buf].filetype
    if ft == '' then
        require('utils.misc').err 'Cannot start parser, ft not assigned'
        return
    end

    local ok, lang = pcall(vim.treesitter.language.get_lang, ft)
    if not ok or not lang then
        return
    end

    local ok1 = pcall(vim.treesitter.start, buf, lang)
    if not ok1 then
        require('utils.misc').err(string.format('Cannot start parser for `%s`', lang))
    end
end

---@type LazyPluginSpec
local TreeSitter = {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    event = { 'BufReadPre', 'VeryLazy' },
    opts = {
        install_dir = vim.fn.stdpath 'data' .. '/site',
    },
    init = function()
        local langs = require('modules.lang').get_ts_enable_langs()
        if #langs ~= 0 then
            vim.api.nvim_create_autocmd({ 'FileType' }, {
                pattern = langs,
                callback = function(args)
                    safe_ts_start(args.buf)
                end,
            })
        end
    end,
    config = function(_, opts)
        local TS = require 'nvim-treesitter'
        TS.setup(opts)
        TS.install(TSEnsureInstalled)
    end,
}

return TreeSitter

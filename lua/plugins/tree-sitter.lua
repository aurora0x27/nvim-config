-- Regex highlighter

-- if true then return {} end   -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local TSEnsureInstalled = {
    'c',
    'lua',
    'luadoc',
    'asm',
    'vim',
    'cpp',
    'rust',
    'python',
    'json',
    'yaml',
    'toml',
    'bash',
    'fish',
    'awk',
    'kdl',
    'dosini',
    'diff',
    'cmake',
    'git_config',
    'gitignore',
    'gitcommit',
    'git_rebase',
    'gitattributes',
    'astro',
    'html',
    'css',
    'vim',
    'vimdoc',
    'typst',
    'latex',
    'go',
    'glsl',
    'llvm',
    'ninja',
    'markdown',
    'markdown_inline',
}

local TreeSitter = {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    event = 'VeryLazy',
    opts = {
        install_dir = vim.fn.stdpath 'data' .. '/site',
    },
    config = function(_, opts)
        local TS = require 'nvim-treesitter'
        TS.setup(opts)
        TS.install(TSEnsureInstalled)
        vim.api.nvim_create_autocmd('FileType', {
            pattern = TSEnsureInstalled,
            callback = function()
                vim.treesitter.start()
            end,
        })
    end,
}

return TreeSitter

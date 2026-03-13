--- Simple lang specs
---@type LangSpec[]
return {
    {
        ft = 'nginx',
        treesitter = true,
        formatter = { name = 'nginxfmt', packname = 'nginx-config-formatter' },
    },

    { ft = 'dosini', treesitter = 'ini' },
    { ft = 'gitconfig', treesitter = 'git_config' },
    { ft = 'gitrebase', treesitter = 'git_rebase' },

    {
        ft = {
            'asm',
            'awk',
            'bash',
            'diff',
            'dockerfile',
            'fish',
            'gitattributes',
            'gitcommit',
            'gitignore',
            'glsl',
            'javascript',
            'kdl',
            'latex',
            'llvm',
            'luadoc',
            'ninja',
            'query',
            'scheme',
            'tablegen',
            'toml',
            'typescript',
            'vim',
            'vimdoc',
            'yaml',
        },
        treesitter = true,
    },

    {
        ft = { 'json', 'css', 'html', 'astro' },
        treesitter = true,
        formatter = { name = 'prettier' },
    },
}

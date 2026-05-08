--- Simple lang specs
---@type LangSpec[]
return {
  {
    ft = 'nginx',
    treesitter = false,
    formatter = { name = 'nginxfmt', packname = 'nginx-config-formatter' },
  },

  { ft = 'dosini', treesitter = 'ini' },
  { ft = 'gitconfig', treesitter = 'git_config' },
  { ft = 'gitrebase', treesitter = 'git_rebase' },
  { ft = 'toml', treesitter = true, formatter = { name = 'taplo' } },

  {
    ft = {
      'asm',
      'awk',
      'bash',
      'diff',
      'dockerfile',
      'editorconfig',
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

--------------------------------------------------------------------------------
--- Meta source for profile option generation
--------------------------------------------------------------------------------
-- luacheck: ignore 631 -- max line length

---@type table<string, ProfileManifestDecl>
local Decls = {
  transparent_mode = {
    type = 'boolean',
    default = false,
    desc = 'enable transparent mode',
    category = 'ui',
    i18n = {
      zh_CN = '启用透明模式',
    },
  },

  diagnose_mode = {
    type = 'DiagnoseMode',
    default = 'inline',
    desc = [[diagnose display level.
    options are `'inline'|'detailed'|'pretty'`, `inline` means use virtual text
    to display diagnostic messages, `detailed` means use extra virtual lines,
    `pretty` means use extra plugin -- `tiny-inline-diagnostic` to display]],
    category = 'ui',
    i18n = {
      zh_CN = [[ 诊断显示级别，
      选项为 `'inline'|'detailed'|'pretty'`，`inline` 表示使用虚拟文本显示诊断信息，
      `detailed` 表示使用额外的虚拟行显示诊断信息，`pretty` 表示使用额外的插件
      -- `tiny-inline-diagnostic` 用于显示诊断信息，默认为 `inline`]],
    },
    enum = {
      'inline',
      'pretty',
      'detailed',
    },
  },

  diagnose_level = {
    type = 'DiagnoseLevel',
    default = 'hint',
    desc = 'minimal level of diagnostic messages to display',
    category = 'ui',
    i18n = {
      zh_CN = '要显示的最低诊断信息级别',
    },
    enum = {
      'hint',
      'info',
      'warn',
      'error',
    },
  },

  diagnose_with_fancy_underline = {
    type = 'boolean',
    default = false,
    desc = 'use fancy curl underline. **need terminal and tmux support**',
    category = 'ui',
    i18n = {
      zh_CN = '是否使用花哨的下划线，**需要终端和 tmux 支持**',
    },
  },

  dashboard_art_name = {
    type = 'DashboardArtName',
    default = 'Ayanami Rei',
    desc = 'choose an ascii art on dashboard',
    category = 'ui',
    i18n = {
      zh_CN = '选择仪表盘上的 ASCII 艺术字',
    },
    enum = {
      'DoomNvim',
      'Ayanami Rei',
      'Vscode',
      'Saturn',
      'Saiba Momoi',
      'Lenin',
      'Default',
    },
  },

  emmy_inject_vim_rt = {
    type = 'boolean',
    default = true,
    desc = 'inject vim runtime to `emmylua_ls` workspace config',
    category = 'lsp',
    i18n = {
      zh_CN = '将 Vim 运行时注入到 `emmylua_ls` 工作区配置中',
    },
  },

  emmy_inject_plugin_path = {
    type = 'boolean',
    default = false,
    desc = 'inject plugin path to `emmylua_ls` workspace config',
    category = 'lsp',
    i18n = {
      zh_CN = '将插件路径注入到 `emmylua_ls` 工作区配置中',
    },
  },

  use_emmylua_ls = {
    type = 'boolean',
    default = false,
    desc = 'use `emmylua_ls` as lua language server',
    category = 'lsp',
    i18n = {
      zh_CN = '使用 `emmylua_ls` 作为 Lua 语言服务器',
    },
  },

  use_neogit = {
    type = 'boolean',
    default = false,
    desc = 'use [`neogit`](https://github.com/neogitorg/neogit) as enhanced git client',
    category = 'qol',
    i18n = {
      zh_CN = '使用 [`neogit`](https://github.com/neogitorg/neogit) 作为增强的 git 客户端.',
    },
  },

  use_ufo_as_fold_provider = {
    type = 'boolean',
    default = false,
    desc = 'use [`nvim-ufo`](https://github.com/kevinhwang91/nvim-ufo) as fold provider to get better code fold experience',
    category = 'qol',
    i18n = {
      zh_CN = '使用 [`nvim-ufo`](https://github.com/kevinhwang91/nvim-ufo) 作为默认的折叠提供来源, 获得更好的代码折叠体验.',
    },
  },

  disable_im_switch = {
    type = 'boolean',
    default = false,
    desc = 'disable auto im switcher',
    category = 'qol',
    i18n = {
      zh_CN = '禁用自动输入法切换',
    },
  },

  enable_inlay_hint = {
    type = 'boolean',
    default = false,
    desc = 'default enable lsp inlay hint if has capability',
    category = 'lsp',
    i18n = {
      zh_CN = '默认开启 lsp 的 inlay hint 特性如果有此能力',
    },
  },

  enable_current_line_blame = {
    type = 'boolean',
    default = false,
    desc = 'enable virtual text line blame at the end of line',
    category = 'ui',
    i18n = {
      zh_CN = '启用行尾的虚拟文本行 git blame 显示',
    },
  },

  enable_relative_lnum = {
    type = 'boolean',
    default = false,
    desc = 'use relative number',
    category = 'ui',
    i18n = {
      zh_CN = '使用相对行号',
    },
  },

  blink_use_binary = {
    type = 'boolean',
    default = true,
    desc = 'blink.cmp use prebuild binary instead of building',
    category = 'misc',
    i18n = {
      zh_CN = 'blink.cmp 使用预编译二进制文件代替自行编译',
    },
  },

  lang_blacklist = {
    type = 'string',
    default = 'all',
    desc = [[disabled lang configs, default none, split by ',']],
    category = 'lang',
    i18n = {
      zh_CN = '禁用语言配置，默认禁用，以逗号分隔',
    },
  },

  lang_whitelist = {
    type = 'string',
    default = '',
    desc = [[enabled lang configs, default all, split by ',']],
    category = 'lang',
    i18n = {
      zh_CN = '启用语言配置，默认启用，以逗号分隔',
    },
  },

  lang_levels = {
    type = 'string',
    default = '',
    desc = [[lang feature config.
    syntax: string `c:full;cpp:none;rust:lsp,+ts,-fmt` means enable full
    feature for c, disable all features for cpp, enable tree-sitter and lsp,
    disable formatter for rust.]],
    category = 'lang',
    i18n = {
      zh_CN = [[语言特性配置
      语法：字符串 `c:full;cpp:none;rust:lsp,+ts,-fmt` 表示启用 C 语言的全部功能,
      禁用 C++ 的所有功能，启用 tree-sitter 和 lsp，禁用 Rust 的格式化程序.]],
    },
  },

  statline_scrollbar_style = {
    type = 'StatusScrollbarStyle',
    default = 'moon',
    desc = 'heirline scroll bar style, which displays cursor position',
    category = 'ui',
    i18n = {
      zh_CN = '选择用于显示光标位置的滚动条样式',
    },
    enum = { 'sbar', 'circle', 'moon' },
  },

  bigfile_size_byte = {
    type = 'number',
    default = 2097152,
    desc = 'average byte size',
    category = 'bigfile',
    i18n = {
      zh_CN = '平均字节大小',
    },
  },

  bigfile_size_line = {
    type = 'number',
    default = 100000,
    desc = 'average line length (useful for minified files)',
    category = 'bigfile',
    i18n = {
      zh_CN = '平均行长度（适用于压缩文件）',
    },
  },

  allow_workspace_patch = {
    type = 'boolean',
    default = false,
    desc = 'allow editor patch its behavior according to workspace config',
    category = 'workspace',
    i18n = {
      zh_CN = '允许编辑器根据工作区配置修改其行为',
    },
  },

  workspace_patch_always_restrict = {
    type = 'boolean',
    default = true,
    category = 'workspace',
    desc = 'always enable restrict mode, disable _dofile_ to prevent **ACE**',
    i18n = {
      zh_CN = '始终启用限制模式. 禁用 `dofile` 以防止 **任意代码执行**',
    },
  },

  enable_sticky_buffer = {
    type = 'boolean',
    default = false,
    category = 'ui',
    desc = 'enable sticky buffer for each window',
    i18n = {
      zh_CN = '为每个窗口启用粘性缓冲区',
    },
  },

  clang_format_path = {
    type = 'string',
    default = 'clang-format',
    category = 'lsp',
    desc = 'assign `clang-format` binary path',
    i18n = {
      zh_CN = '指定 `clang-format` 二进制文件路径',
    },
  },

  clangd_path = {
    type = 'string',
    default = 'clangd',
    category = 'lsp',
    desc = 'assign `clangd` binary path',
    i18n = {
      zh_CN = '指定 `clangd` 二进制文件路径',
    },
  },

  integrated_terminal_shell = {
    type = 'string',
    default = 'zsh',
    category = 'terminal',
    desc = 'choose integrated terminal shell, default zsh',
    i18n = {
      zh_CN = '为集成终端设置 shell, 默认为 zsh',
    },
  },

  persist_mode = {
    type = 'string',
    default = 'none',
    category = 'persist',
    desc = 'Enable persistence features. Supported items: `session|undo|shada|swap`',
    i18n = {
      zh_CN = '启用持久化功能。支持：`session|undo|shada|swap`',
    },
  },

  persist_local_mode = {
    type = 'string',
    default = 'none',
    category = 'persist',
    desc = 'Store selected persistence features in the current workspace. Supported items: `session|undo|shada|swap`.',
    i18n = {
      zh_CN = '将指定的持久化功能存储到当前工作区。支持：`session|undo|shada|swap`。',
    },
  },

  persist_local_dir = {
    type = 'string',
    default = '.cache/nvim/',
    category = 'persist',
    desc = 'Workspace-relative directory used to store local persistence data.',
    i18n = {
      zh_CN = '用于存放工作区本地持久化数据的目录（相对于工作区根目录）。',
    },
  },
}

local Category = {
  ui = {
    en = 'UI',
    zh_CN = '用户界面',
  },
  terminal = {
    en = 'Terminal',
    zh_CN = '终端',
  },
  bigfile = {
    en = 'Big File',
    zh_CN = '大文件支持',
  },
  lsp = {
    en = 'LSP',
    zh_CN = 'LSP',
  },
  lang = {
    en = 'Lang',
    zh_CN = '语言模块',
  },
  qol = {
    en = 'QoL',
    zh_CN = '生活质量(QoL)',
  },
  workspace = {
    en = 'Workspace',
    zh_CN = '工作区',
  },
  misc = {
    en = 'Misc',
    zh_CN = '其他',
  },
  persist = {
    en = 'Persistence',
    zh_CN = '持久化',
  },
}

return Decls, Category

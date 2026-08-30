<p align="center">
  <h2 align="center">又一个 Nvim 配置</h2>
</p>

<p align="center">一套<b>模块化且高性能</b>的 Nvim 配置,全部<b><i>手工</i></b>编写</p>

<p align="center">
  <a href="https://github.com/aurora0x27/nvim-config">
    <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/aurora0x27/nvim-config?style=for-the-badge&logo=github&logoColor=D9E0EE&label=github&labelColor=302D41&color=C9CBFF">
  </a>
  <a href="https://codeberg.org/aurora0x27/nvim-config">
    <img alt="Gitea Stars" src="https://img.shields.io/gitea/stars/aurora0x27/nvim-config?gitea_url=https%3A%2F%2Fcodeberg.org&style=for-the-badge&logo=Codeberg&logoColor=D9E0EE&label=codeberg&labelColor=302D41&color=C9CBFF">
  </a>
  <a href="https://codeberg.org/aurora0x27/nvim-config/src/branch/main/LICENSE">
    <img alt="Static Badge" src="https://img.shields.io/badge/license-mit-DDB6F2?style=for-the-badge&logo=opensourceinitiative&logoColor=D9E0EE&label=license&labelColor=302D41">
  </a>
</p>

## 与众不同之处

大多数配置都是插件列表加上选项。而这个配置是**围绕工作流程**进行优化的：

- **以数据而非代码的形式进行配置。** 一个 `nvimrc.json` 文件加上环境变量即可驱动所有功能——特性、语言、诊断。无需费力地在 Lua 代码中摸索。
- **插件更少，行为经过精心调校。** 通知、消息、命令行、标签页和会话功能都经过重新实现，以适应这种工作流程。

此外，还有一些常用功能——代码补全、模糊查找、Treesitter、LSP、格式化、状态栏。没有什么特别之处。

## 示例展示

![仪表盘](./doc/img/Dashboard.webp)

![工作区](./doc/img/Workspace.webp)

## 依赖项

在运行配置之前，需要安装一些二进制文件。

- `make` 用于 Markdown 预览器

- `yarn` 用于 Markdown 预览器

- `websocat` 用于typst 预览器

- `rg` 用于模糊查找器

- `fzf` 用于模糊查找器

- `gcc/clang` 一個 c 編譯器, 用于 tree-sitter 解析器编译

- `tree-sitter` 被 `nvim-treesitter` 需要

- `fcitx5-remote`（Linux、MacOS 系统）用于 ime-switcher（输入法切换器）

- `win32yank.exe`（Windows 系统）用于系统剪贴板支持

- `cargo` 完整的 `rust` 工具鏈, 是 `blink.cmp` 的可選依賴

> [!CAUTION]
>
> 本配置要求 **nvim >= 0.12**

## 立即尝试

无需修改您的原始配置，即可立即尝试。

```bash
./venv # 启动一个虚拟环境 shell，它实际上是一个沙盒 shell，隔离了插件、缓存和运行时文件
nvim # 在此配置下启动 Neovim，无需修改您的 ~/.local/share 文件
```

或者，您可以将仓库下载到 `~/.config/<name>`, 然后运行 `NVIM_APPNAME=<name> nvim` 来启动它。

## 可选特性

某些功能是可选的，由一个json文件——`nvimrc.json` 控制，该文件应放置在您的配置目录下。
以下是可自定义项目：

<!-- docgen@profile -->

- 大文件支持
  - _`bigfile_size_byte`_ — 平均字节大小
    - **Type:** `number`
    - **ENV:** `NVIM_BIGFILE_SIZE_BYTE`
    - **Defaults:** `2097152`

  - _`bigfile_size_line`_ — 平均行长度（适用于压缩文件）
    - **Type:** `number`
    - **ENV:** `NVIM_BIGFILE_SIZE_LINE`
    - **Defaults:** `100000`

- 语言模块
  - _`lang_blacklist`_ — 禁用语言配置，默认禁用，以逗号分隔
    - **Type:** `string`
    - **ENV:** `NVIM_LANG_BLACKLIST`
    - **Defaults:** `'all'`

  - _`lang_levels`_ — 语言特性配置
    语法：字符串 `c:full;cpp:none;rust:lsp,+ts,-fmt` 表示启用 C 语言的全部功能,
    禁用 C++ 的所有功能，启用 tree-sitter 和 lsp，禁用 Rust 的格式化程序.
    - **Type:** `string`
    - **ENV:** `NVIM_LANG_LEVELS`
    - **Defaults:** `''`

  - _`lang_whitelist`_ — 启用语言配置，默认启用，以逗号分隔
    - **Type:** `string`
    - **ENV:** `NVIM_LANG_WHITELIST`
    - **Defaults:** `''`

- LSP
  - _`clang_format_path`_ — 指定 `clang-format` 二进制文件路径
    - **Type:** `string`
    - **ENV:** `NVIM_CLANG_FORMAT_PATH`
    - **Defaults:** `'clang-format'`

  - _`clangd_path`_ — 指定 `clangd` 二进制文件路径
    - **Type:** `string`
    - **ENV:** `NVIM_CLANGD_PATH`
    - **Defaults:** `'clangd'`

  - _`enable_inlay_hint`_ — 默认开启 lsp 的 inlay hint 特性如果有此能力
    - **Type:** `boolean`
    - **ENV:** `NVIM_ENABLE_INLAY_HINT`
    - **Defaults:** `false`

  - _`use_emmylua_ls`_ — 使用 `emmylua_ls` 作为 Lua 语言服务器
    - **Type:** `boolean`
    - **ENV:** `NVIM_USE_EMMYLUA_LS`
    - **Defaults:** `false`

- 其他
  - _`blink_use_binary`_ — blink.cmp 使用预编译二进制文件代替自行编译
    - **Type:** `boolean`
    - **ENV:** `NVIM_BLINK_USE_BINARY`
    - **Defaults:** `true`

- 持久化
  - _`persist_local_dir`_ — 用于存放工作区本地持久化数据的目录（相对于工作区根目录）。
    - **Type:** `string`
    - **ENV:** `NVIM_PERSIST_LOCAL_DIR`
    - **Defaults:** `'.cache/nvim/'`

  - _`persist_local_mode`_ — 将指定的持久化功能存储到当前工作区。支持：`session|undo|shada|swap`。
    - **Type:** `string`
    - **ENV:** `NVIM_PERSIST_LOCAL_MODE`
    - **Defaults:** `'none'`

  - _`persist_mode`_ — 启用持久化功能。支持：`session|undo|shada|swap`
    - **Type:** `string`
    - **ENV:** `NVIM_PERSIST_MODE`
    - **Defaults:** `'none'`

- 生活质量(QoL)
  - _`disable_im_switch`_ — 禁用自动输入法切换
    - **Type:** `boolean`
    - **ENV:** `NVIM_DISABLE_IM_SWITCH`
    - **Defaults:** `false`

  - _`use_neogit`_ — 使用 [`neogit`](https://github.com/neogitorg/neogit) 作为增强的 git 客户端.
    - **Type:** `boolean`
    - **ENV:** `NVIM_USE_NEOGIT`
    - **Defaults:** `false`

  - _`use_ufo_as_fold_provider`_ — 使用 [`nvim-ufo`](https://github.com/kevinhwang91/nvim-ufo) 作为默认的折叠提供来源, 获得更好的代码折叠体验.
    - **Type:** `boolean`
    - **ENV:** `NVIM_USE_UFO_AS_FOLD_PROVIDER`
    - **Defaults:** `false`

- 终端
  - _`integrated_terminal_shell`_ — 为集成终端设置 shell, 默认为 zsh
    - **Type:** `string`
    - **ENV:** `NVIM_INTEGRATED_TERMINAL_SHELL`
    - **Defaults:** `'zsh'`

- 用户界面
  - _`dashboard_art_name`_ — 选择仪表盘上的 ASCII 艺术字
    - **Type:** `DashboardArtName`
    - **ENV:** `NVIM_DASHBOARD_ART_NAME`
    - **Defaults:** `'Ayanami Rei'`

  - _`diagnose_level`_ — 要显示的最低诊断信息级别
    - **Type:** `DiagnoseLevel`
    - **ENV:** `NVIM_DIAGNOSE_LEVEL`
    - **Defaults:** `'hint'`

  - _`diagnose_mode`_ — 诊断显示级别，
    选项为 `'inline'|'detailed'|'pretty'`，`inline` 表示使用虚拟文本显示诊断信息，
    `detailed` 表示使用额外的虚拟行显示诊断信息，`pretty` 表示使用额外的插件
    -- `tiny-inline-diagnostic` 用于显示诊断信息，默认为 `inline`
    - **Type:** `DiagnoseMode`
    - **ENV:** `NVIM_DIAGNOSE_MODE`
    - **Defaults:** `'inline'`

  - _`diagnose_with_fancy_underline`_ — 是否使用花哨的下划线，**需要终端和 tmux 支持**
    - **Type:** `boolean`
    - **ENV:** `NVIM_DIAGNOSE_WITH_FANCY_UNDERLINE`
    - **Defaults:** `false`

  - _`enable_current_line_blame`_ — 启用行尾的虚拟文本行 git blame 显示
    - **Type:** `boolean`
    - **ENV:** `NVIM_ENABLE_CURRENT_LINE_BLAME`
    - **Defaults:** `false`

  - _`enable_relative_lnum`_ — 使用相对行号
    - **Type:** `boolean`
    - **ENV:** `NVIM_ENABLE_RELATIVE_LNUM`
    - **Defaults:** `false`

  - _`enable_sticky_buffer`_ — 为每个窗口启用粘性缓冲区
    - **Type:** `boolean`
    - **ENV:** `NVIM_ENABLE_STICKY_BUFFER`
    - **Defaults:** `false`

  - _`statline_scrollbar_style`_ — 选择用于显示光标位置的滚动条样式
    - **Type:** `StatusScrollbarStyle`
    - **ENV:** `NVIM_STATLINE_SCROLLBAR_STYLE`
    - **Defaults:** `'moon'`

  - _`transparent_mode`_ — 启用透明模式
    - **Type:** `boolean`
    - **ENV:** `NVIM_TRANSPARENT_MODE`
    - **Defaults:** `false`

- 工作区
  - _`allow_workspace_patch`_ — 允许编辑器根据工作区配置修改其行为
    - **Type:** `boolean`
    - **ENV:** `NVIM_ALLOW_WORKSPACE_PATCH`
    - **Defaults:** `false`

  - _`workspace_patch_always_restrict`_ — 始终启用限制模式. 禁用 `dofile` 以防止 **任意代码执行**
    - **Type:** `boolean`
    - **ENV:** `NVIM_WORKSPACE_PATCH_ALWAYS_RESTRICT`
    - **Defaults:** `true`

    <!-- enddoc@profile -->

> [!NOTE]
>
> 环境变量仍然可用，且优先级高于 JSON 配置值。

## 许可证 [MIT](../LICENSE)

> **該簡體中文版本完全由谷歌翻譯生成**

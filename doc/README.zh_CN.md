# 又一个 NVIM 配置

[English](../README.md) | 中文

一套**模块化且高性能**的 Nvim 配置，全部***手工***编写

> [!NOTE]
>
> 这套配置原本是“精简版”的，为什么现在变得复杂了呢？
> 随着配置的不断增长，扁平化的结构变得难以维护。
> 新的模块化架构将策略（启用哪些功能）与实现（插件设置）分离。
> 现在，它是一种**数据驱动的**配置。
>
> - `lua/modules/profile/` 定义编辑器的行为方式。
> - `lua/modules/lang/` 定义每种语言提供的功能。
>   这使得该配置成为一个框架，而不仅仅是一组点文件。

##  示例展示 

![仪表盘](./img/Dashboard.png)

![工作区](./img/Workspace.png)

## 功能

- 模块化配置文件系统：在不同配置配置文件之间无缝切换。只需修改 JSON 表，即可自定义编辑器在不同设备/操作系统上的行为。

- 细粒度语言控制：通过环境变量，对 LSP、Treesitter 和 Formatter 进行精细控制，

- 完全由自行实现的运行时层构成：摒弃了 `noice` 和 `snacks`，用简单易懂的代码实现提升用户体验的功能，完全不需要任何理解能力。

- 动态功能：根据环境自动调整功能（例如，Neovim 版本、环境变量）。

- 代码组织良好(注释也很详细), 便于初学者理解——良好的代码就是最好的文档😈😈😈

## 依赖项

在运行配置之前，需要安装一些二进制文件。

- `make` 用于 Markdown 预览器

- `yarn` 用于 Markdown 预览器

- `rg` 用于模糊查找器

- `fzf` 用于模糊查找器

- `gcc/clang` 一個 c 編譯器, 用于 tree-sitter 解析器编译

- `tree-sitter` 被 `nvim-treesitter` 需要

- `fcitx5-remote`（Linux、MacOS 系统）用于 ime-switcher（输入法切换器）

- `win32yank.exe`（Windows 系统）用于系统剪贴板支持

- `cargo` 完整的 `rust` 工具鏈, 是 `blink.cmp` 的可選依賴

##  立即尝试 

无需修改您的原始配置，即可立即尝试。

```bash
./venv # 启动一个虚拟环境 shell，它实际上是一个沙盒 shell，隔离了插件、缓存和运行时文件
nvim # 在此配置下启动 Neovim，无需修改您的 ~/.local/share 文件
```

或者，您可以将仓库下载到 `~/.config/<name>`, 然后运行 `NVIM_APPNAME=<name> nvim` 来启动它。

## 基本功能

- [x] 自动补全
- [x] 状态栏
- [x] 颜色和注释高亮
- [x] 文件系统资源管理器
- [x] Markdown 预览
- [x] Markdown 渲染器
- [x] 大纲
- [x] 集成终端
- [x] 模糊查找器
- [x] LSP 支持
- [x] 格式化程序
- [x] SSH 剪贴板支持（**需要 tmux 额外配置**）
- [x] 输入法自动切换（**仅限 Linux 和 macOS**）
- [x] 工作区补丁
- [x] Typst 支持
- [x] Windows 支持
- [x] 集中式语言特性开关
- [x] Json-env 组合配置文件系统

## 可选特性

某些功能是可选的，由一个json文件——`nvimrc.json`——控制，该文件应放置在您的配置目录下。
以下是可自定义项目：

- 用户界面
  - _`transparent_mode`_ 启用透明模式
  - _`dashboard_art_name`_ 选择仪表盘上的 ASCII 艺术字
  - _`statline_scrollbar_style`_ 选择用于显示光标位置的滚动条样式
  - _`diagnose_inline`_ 不使用虚拟线显示诊断信息
  - _`enable_current_line_blame`_ 启用行尾的虚拟文本行错误信息显示
  - _`enable_dropbar`_ 为每个窗口启用面包屑导航

- 语言模块
  - _`lang_blacklist`_ 禁用语言配置，默认禁用，以逗号分隔
  - _`lang_whitelist`_ 启用语言配置，默认启用，以逗号分隔
  - _`lang_levels`_ 语言特性配置，语法：字符串 `c:full;cpp:none;rust:lsp,+ts,-fmt` 表示启用 C 语言的全部功能，禁用 C++ 的所有功能，启用 tree-sitter 和 lsp，禁用 Rust 的格式化程序。

- LSP
  - _`enable_lsp`_ 启用 LSP **如果 nvim 版本 <= 0.11，则禁用 LSP**
  - _`use_emmylua_ls`_ 使用 `emmylua_ls` 作为 Lua 语言服务器
  - _`workspace_inject_plugin_path`_ 将插件路径注入到 `emmylua_ls` 工作区配置中
  - _`workspace_inject_vim_rt`_ 将 Vim 运行时注入到 `emmylua_ls` 工作区配置中
  - `clang_format_path` 指定 `clang-format` 二进制文件路径
  - `clangd_path` 指定 `clangd` 二进制文件路径

- 大文件支持
  - _`bigfile_size_byte`_ 平均字节大小
  - _`bigfile_size_line`_ 平均行长度（适用于压缩文件）

- 工作区
  - `allow_workspace_patch` 允许编辑器根据工作区配置修改其行为
  - `workspace_patch_always_restrict` 始终启用限制模式，禁用 `dofile` 以防止 **ACE**

- 其他
  - _`sandbox_mode`_ 控制沙盒功能 `sesson|undo|shada|swap|wb`，其中 `wb` 用于写回功能
  - _`disable_im_switch`_ 禁用自动 Im 切换器
  - _`blink_use_binary`_ 使用预编译二进制文件代替自行编译

以下是默认值：

```lua
local defaults = {
  blink_use_binary = true,
  dashboard_art_name = "Ayanami Rei",
  diagnose_inline = false,
  disable_im_switch = false,
  enable_current_line_blame = false,
  enable_lsp = true,
  lang_blacklist = "all",
  lang_levels = "",
  lang_whitelist = "",
  sandbox_mode = "none",
  statline_scrollbar_style = "moon",
  transparent_mode = false,
  use_emmylua_ls = false,
  workspace_inject_plugin_path = false,
  workspace_inject_vim_rt = true
  bigfile_size_byte = 2097152,
  bigfile_size_line = 100000,
  allow_workspace_patch = false,
  workspace_patch_always_restrict = true,
}
```

> [!NOTE]
>
> 环境变量仍然可用，且优先级高于 JSON 配置值。

## 可能需要的功能

- Markdown 表格格式

- Markdown 中的图像预览（部分支持）

- 搜索增强

- 代码折叠范围在展开时高亮

## 待办事项列表

- LaTeX 预览

- 收集默認值, 並移除硬編碼選項

> **該簡體中文版本完全由谷歌翻譯生成**

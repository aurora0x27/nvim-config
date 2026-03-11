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
> - lua/modules/profile/：定义编辑器的行为方式。
> - lua/modules/lang/：定义每种语言提供的功能。
>   这使得该配置成为一个框架，而不仅仅是一组点文件。

## ⚡示例展示⚡

![仪表盘](./img/Dashboard.png)

![工作区](./img/Workspace.png)

## 功能

- 模块化配置文件系统：在不同配置配置文件之间无缝切换。只需修改 JSON 表，即可自定义编辑器在不同设备/操作系统上的行为。

- 细粒度语言控制：通过环境变量，对 LSP、Treesitter 和 Formatter 进行精细控制，

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

## ⚡立即尝试⚡

无需修改您的原始配置，即可立即尝试。

```bash
./venv # 启动一个虚拟环境 shell，它实际上是一个沙盒 shell，隔离了插件、缓存和运行时文件
vi # 在此配置下启动 Neovim，无需修改您的 ~/.local/share 文件
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
- [x] 任务运行基础设施 (**Overseer**)
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

- 语言模块
  - _`silent_lang_diag`_ 不输出语言加载器的日志
  - _`lang_blacklist`_ 禁用语言配置，默认禁用，以逗号分隔
  - _`lang_whitelist`_ 启用语言配置，默认启用，以逗号分隔
  - _`lang_levels`_ 语言特性配置，语法：字符串 `c:full;cpp:none;rust:lsp,+ts,-fmt` 表示启用 C 语言的全部功能，禁用 C++ 的所有功能，启用 tree-sitter 和 lsp，禁用 Rust 的格式化程序。

- LSP
  - _`enable_lsp`_ 启用 LSP **如果 nvim 版本 <= 0.11，则禁用 LSP**
  - _`use_emmylua_ls`_ 使用 `emmylua_ls` 作为 Lua 语言服务器
  - _`workspace_inject_plugin_path`_ 将插件路径注入到 `emmylua_ls` 工作区配置中
  - _`workspace_inject_vim_rt`_ 将 Vim 运行时注入到 `emmylua_ls` 工作区配置中

- 大文件支持
  - _`bigfile_size_byte`_ 平均字节大小
  - _`bigfile_size_line`_ 平均行长度（适用于压缩文件）

- 其他
  - _`sandbox_mode`_ 控制沙盒功能 `sesson|undo|shada|swap|wb`，其中 `wb` 用于写回功能
  - _`silent_profile_diag`_ 不输出配置文件加载器的日志
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
  silent_lang_diag = false,
  silent_profile_diag = false,
  statline_scrollbar_style = "moon",
  transparent_mode = false,
  use_emmylua_ls = false,
  workspace_inject_plugin_path = false,
  workspace_inject_vim_rt = true
  bigfile_size_byte = 2097152,
  bigfile_size_line = 100000,
}
```

> [!NOTE]
>
> 环境变量仍然可用，且优先级高于 JSON 配置值。

## 设计理念

与专注于功能“捆绑”的标准 Neovim 发行版不同, 此配置架构为**配置引擎**。它将配置视为结构化数据, 并将加载过程视为受控管道。

### 1. 机制与策略分离

此设置的核心是**机制**（加载器）。它不关心*加载什么*；

它只关心*如何*扫描目录、解析模块路径和聚合数据。

**策略**（`LangSpec` 或 `PluginSpec`）是纯数据。

- **优势**：您可以通过创建一个声明式文件来添加对新语言的支持，而无需修改编排逻辑。

### 2. 环境驱动的运行时掩码

此编辑器应能适应上下文，而无需更改代码。通过使用诸如 `NVIM_LANG_WHITELIST` 和 `NVIM_LANG_BLACKLIST` 之类的环境变量.
配置允许“运行时屏蔽”。

- **逻辑**：白名单充当“允许”机制，覆盖任何“全部拒绝”黑名单。

- **用例**：调试核心问题？执行 `NVIM_LANG_BLACKLIST=all nvim` 即可立即清除配置。

### 3. 结构化原子性

每个模块（例如，`config.langs.python`）都是一个原子单元。我在加载期间使用**递归路径栈**，以确保文件系统的层次结构
反映在最终的配置状态中。

这避免了全局命名空间污染，并使“配置集合”（一个文件定义多个子实体）成为可能且安全。

### 对比：发行版/典型 nvim 配置 vs. 本引擎

| 特性         | 典型配置/发行版   | 本配置                 |
| ------------ | ----------------- | ---------------------- |
| **加载方式** | 过程式 & 线性加载 | 扫描式 & 聚合式加载    |
| **切换方式** | 硬编码布尔值      | 语义化环境掩码 (+/-)   |
| **数据结构** | 命令式设置调用    | 声明式规范（模式驱动） |
| **理念**     | “包含所有内容”    | “仅加载白名单中的内容” |

## 可能需要的功能

- Markdown 表格格式

- Markdown 中的图像预览（部分支持）

- 搜索增强

- 代码折叠范围在展开时高亮

## 待办事项列表

- LaTeX 预览

- 收集默認值, 並移除硬編碼選項

> **本自述文件部分内容由人工智能生成，但经过人工严格审核。**
>
> **該簡體中文版本完全由谷歌翻譯生成**

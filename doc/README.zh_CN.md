# 又一个 NVIM 配置

[English](../README.md) | 中文

一套精简的 Nvim 配置，全部*手工*编写

## ⚡示例展示⚡

![仪表盘](./img/Dashboard.png)

![工作区](./img/Workspace.png)

## 功能

- 仅包含基本但必要的功能

- 代码结构清晰，便于初学者理解

## 依赖项

在运行配置之前，需要安装一些二进制文件。

- `make` 用于 Markdown 预览器

- `yarn` 用于 Markdown 预览器

- `rg` 用于模糊查找器

- `fzf` 用于模糊查找器

- `gcc` 用于 tree-sitter 解析器编译

- `fcitx5-remote`（Linux、MacOS 系统）用于 ime-switcher（输入法切换器）

- `win32yank.exe`（Windows 系统）用于系统剪贴板支持

## ⚡立即体验⚡

无需替换原始配置即可立即体验

```bash

./venv # 启动一个虚拟环境 shell，`nvim-debug` 将自动添加到路径

vi # 使用此配置启动 Neovim，无需更改 ~/.local/share

```

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

## 可选特性

配置中有一些可选特性, 它们由环境变量控制.

- *NVIM_SESSION_DISABLED* 禁用会话恢复

- *NVIM_TRANSPARENT_MODE* 启用透明模式

- *NVIM_DASHBOARD_ART_NAME* 更换启动页面的 ascii 艺术

- *NVIM_DIAGNOSTIC_INLINE* 禁用虚拟行显示诊断信息

- *NVIM_USE_EMMYLUA_LS* 使用 `emmylua_ls` 作为 lua 语言服务器

- *NVIM_WORKSPACE_INJECT_VIM_RT* 将 vim 运行时注入 `emmylua_ls` 工作区

- *NVIM_WORKSPACE_INJECT_VIM_RT* 在 `emmylua_ls` 的工作区配置中注入 vim 运行时

- *NVIM_WORKSPACE_INJECT_PLUGIN_PATH* 在 `emmylua_ls` 的工作区配置中注入插件路径

- *NVIM_ENABLE_XMAKE_LS* 启用 `xmake_ls`

## 可能需要的功能

- Markdown 表格格式

- Markdown 中的图像预览（部分支持）

- 搜索增强

- 代码折叠范围在展开时高亮

## 待办事项列表

- LaTeX 预览

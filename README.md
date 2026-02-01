# YET ANOTHER NVIM CONFIG

English | [中文](./doc/README.zh_CN.md)

A streamlined set of configurations for Nvim which is writen all *by hand*

## ⚡Showcase ⚡

![Dashboard](./doc/img/Dashboard.png)

![Workspace](./doc/img/Workspace.png)

## Feature

- Only with basic but necessary functionality

- Well organized code for beginers to understand

## Dependency

Some binaries should be installed before launch the configuration.

- `make` for markdown previewer

- `yarn` for markdown previewer

- `rg` for fuzzy finder

- `fzf` for fuzzy finder

- `gcc` for tree-sitter parser compilation

- `fcitx5-remote` *Linux,MacOS* for ime-switcher

- `win32yank.exe` *Windows* for system clipboard support

## ⚡Try it now ⚡

You can try it immediately without replacing your origin configurations

```bash
./venv # Launch a virtual env shell, `nvim-debug` will be added to path automaticly
vi     # Launch neovim on this config, without make changes to your ~/.local/share
```

## Basic functionalities

- [x] Auto complition
- [x] Status line
- [x] Color and comment highlight
- [x] File system explorer
- [x] Markdown preview
- [x] Markdown renderer
- [x] Outline
- [x] Intergrated terminal
- [x] Fuzzy finder
- [x] LSP support
- [x] Formatter
- [x] SSH clipboard support(**Need tmux extra config**)
- [x] Input method auto switch (**On Linux and MacOS**)
- [x] Workspace patch
- [x] Typst support
- [x] Task runner infrastructure (**Overseer**)
- [x] Windows Support

## Optional features

Some features are optional, controlled by environment variables.

- *NVIM_SESSION_DISABLED* disable session recovery

- *NVIM_TRANSPARENT_MODE* enable transparent mode

- *NVIM_DASHBOARD_ART_NAME* choose an ascii art on dashboard

- *NVIM_DIAGNOSTIC_INLINE* do not use virtual lines to display diagnostic messages

- *NVIM_USE_EMMYLUA_LS* use `emmylua_ls` as lua language server

- *NVIM_WORKSPACE_INJECT_VIM_RT* inject vim runtime to `emmylua_ls` workspace config

- *NVIM_WORKSPACE_INJECT_PLUGIN_PATH* inject plugin path to `emmylua_ls` workspace config

- *NVIM_ENABLE_XMAKE_LS* enable `xmake_ls`

- *NVIM_ENABLE_GIT_LINE_BLAME* enable virtual text line blame at the end of line

- *NVIM_ENABLE_JAVA_LS* enable java lsp `jdtls`

- *NVIM_ENABLE_GOPLS* enable golang lsp `gopls`

- *NVIM_DISABLE_IM_SWITCH* disable auto im switcher

## Maybe wanted features

- Markdown Table Format

- Image preview in markdown(Partly support)

- Search enhance

- Fold range highlighting on unfolding

- AsciiMode -- No nerd font

## TODO List

- Latex preview

- Collect assets and remove some hard coded options

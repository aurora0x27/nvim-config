# YET ANOTHER NVIM CONFIG

English | [中文](./doc/README.zh_CN.md)

A **Modular & High-performance** set of configurations for Nvim which is written all **_by hand_**

> [!NOTE]
>
> This config is used to be `streamlined`, why the complexity now?
> As the configuration grew, a flat structure became hard to maintain.
> The new Modular Architecture separates Policy (what to enable) from Implementation (plugin setup).
> It is now a **data driven** configuration.
>
> - `lua/core/profile/` Defines how the editor behaves.
> - `lua/core/lang/` Defines what each language provides.
>   This makes the config a framework rather than just a set of dotfiles.

## Showcase

![Dashboard](./doc/img/Dashboard.webp)

![Workspace](./doc/img/Workspace.webp)

## Feature

- Modular Profile System: Switch between different configuration profiles seamlessly. Customize editor behavior on
  different device/os just by modify a JSON table.

- Granular Language Control: Fine-grained control over LSP, Treesitter, and Formatter on a
  per-language basis via environment variables.

- Filled with self-implemented runtime layers: Throw away `noice` and `snacks`, implement qol functionalities with
  simple and easy-to-understand code, requiring absolutely no comprehension.

- Dynamic Capabilities: Automatic adjustment of features based on the environment
  (e.g., Neovim version, environment variables).

- Well organized code(also well annotioned) for beginners to understand -- good code is the best document 😈😈😈

## Dependency

Some binaries should be installed before launch the configuration.

- `make` for markdown previewer

- `yarn` for markdown previewer

- `websocat` for typst previewer

- `rg` for fuzzy finder

- `fzf` for fuzzy finder

- `gcc/clang` anyways, a c compiler for tree-sitter parser compilation

- `tree-sitter` required by nvim-treesitter

- `fcitx5-remote` _Linux,MacOS_ for ime-switcher

- `win32yank.exe` _Windows_ for system clipboard support

- `cargo` full rust toolchain, **optionally** required by blink.cmp

## Try it now

You can try it immediately without replacing your origin configurations.

```bash
./venv # Launch a virtual env shell, it's actually a sanbox shell that isolates plugins, cache and runtime file

nvim     # Launch neovim on this config, without making changes to your ~/.local/share
```

Or, you may download the repo to `~/.config/<name>`, and run `NVIM_APPNAME=<name> nvim` to launch

## Implemented functionalities

- [x] Auto completion
- [x] Status line
- [x] Color and comment highlight
- [x] File system explorer
- [x] Markdown preview
- [x] Markdown renderer
- [x] Outline
- [x] Integrated terminal
- [x] Fuzzy finder
- [x] LSP support
- [x] Formatter
- [x] SSH clipboard support(**Need tmux extra config**)
- [x] Input method auto switch (**On Linux and MacOS**)
- [x] Workspace patch
- [x] Typst support
- [x] Windows Support
- [x] Centralized lang feature switch
- [x] JSON-env combined profile system

## Profile Options

Some features are optional, controlled by a JSON file -- `nvimrc.json`, this file should be placed under your config
dir. Here're customizable items:

<!-- docgen@profile -->

- Big File
  - _`bigfile_size_byte`_ — average byte size
    - **Type:** `number`
    - **ENV:** `NVIM_BIGFILE_SIZE_BYTE`
    - **Defaults:** `2097152`

  - _`bigfile_size_line`_ — average line length (useful for minified files)
    - **Type:** `number`
    - **ENV:** `NVIM_BIGFILE_SIZE_LINE`
    - **Defaults:** `100000`

- Lang
  - _`lang_blacklist`_ — disabled lang configs, default none, split by ','
    - **Type:** `string`
    - **ENV:** `NVIM_LANG_BLACKLIST`
    - **Defaults:** `'all'`

  - _`lang_levels`_ — lang feature config.
    syntax: string `c:full;cpp:none;rust:lsp,+ts,-fmt` means enable full
    feature for c, disable all features for cpp, enable tree-sitter and lsp,
    disable formatter for rust.
    - **Type:** `string`
    - **ENV:** `NVIM_LANG_LEVELS`
    - **Defaults:** `''`

  - _`lang_whitelist`_ — enabled lang configs, default all, split by ','
    - **Type:** `string`
    - **ENV:** `NVIM_LANG_WHITELIST`
    - **Defaults:** `''`

- LSP
  - _`clang_format_path`_ — assign `clang-format` binary path
    - **Type:** `string`
    - **ENV:** `NVIM_CLANG_FORMAT_PATH`
    - **Defaults:** `'clang-format'`

  - _`clangd_path`_ — assign `clangd` binary path
    - **Type:** `string`
    - **ENV:** `NVIM_CLANGD_PATH`
    - **Defaults:** `'clangd'`

  - _`emmy_inject_plugin_path`_ — inject plugin path to `emmylua_ls` workspace config
    - **Type:** `boolean`
    - **ENV:** `NVIM_EMMY_INJECT_PLUGIN_PATH`
    - **Defaults:** `false`

  - _`emmy_inject_vim_rt`_ — inject vim runtime to `emmylua_ls` workspace config
    - **Type:** `boolean`
    - **ENV:** `NVIM_EMMY_INJECT_VIM_RT`
    - **Defaults:** `true`

  - _`enable_inlay_hint`_ — default enable lsp inlay hint if has capability
    - **Type:** `boolean`
    - **ENV:** `NVIM_ENABLE_INLAY_HINT`
    - **Defaults:** `false`

  - _`use_emmylua_ls`_ — use `emmylua_ls` as lua language server
    - **Type:** `boolean`
    - **ENV:** `NVIM_USE_EMMYLUA_LS`
    - **Defaults:** `false`

- Misc
  - _`blink_use_binary`_ — blink.cmp use prebuild binary instead of building
    - **Type:** `boolean`
    - **ENV:** `NVIM_BLINK_USE_BINARY`
    - **Defaults:** `true`

- Persistence
  - _`persist_local_dir`_ — Workspace-relative directory used to store local persistence data.
    - **Type:** `string`
    - **ENV:** `NVIM_PERSIST_LOCAL_DIR`
    - **Defaults:** `'.cache/nvim/'`

  - _`persist_local_mode`_ — Store selected persistence features in the current workspace. Supported items: `session|undo|shada|swap`.
    - **Type:** `string`
    - **ENV:** `NVIM_PERSIST_LOCAL_MODE`
    - **Defaults:** `'none'`

  - _`persist_mode`_ — Enable persistence features. Supported items: `session|undo|shada|swap`
    - **Type:** `string`
    - **ENV:** `NVIM_PERSIST_MODE`
    - **Defaults:** `'none'`

- QoL
  - _`disable_im_switch`_ — disable auto im switcher
    - **Type:** `boolean`
    - **ENV:** `NVIM_DISABLE_IM_SWITCH`
    - **Defaults:** `false`

  - _`use_neogit`_ — use [`neogit`](https://github.com/neogitorg/neogit) as enhanced git client
    - **Type:** `boolean`
    - **ENV:** `NVIM_USE_NEOGIT`
    - **Defaults:** `false`

  - _`use_ufo_as_fold_provider`_ — use [`nvim-ufo`](https://github.com/kevinhwang91/nvim-ufo) as fold provider to get better code fold experience
    - **Type:** `boolean`
    - **ENV:** `NVIM_USE_UFO_AS_FOLD_PROVIDER`
    - **Defaults:** `false`

- Terminal
  - _`integrated_terminal_shell`_ — choose integrated terminal shell, default zsh
    - **Type:** `string`
    - **ENV:** `NVIM_INTEGRATED_TERMINAL_SHELL`
    - **Defaults:** `'zsh'`

- UI
  - _`dashboard_art_name`_ — choose an ascii art on dashboard
    - **Type:** `DashboardArtName`
    - **ENV:** `NVIM_DASHBOARD_ART_NAME`
    - **Defaults:** `'Ayanami Rei'`

  - _`diagnose_level`_ — minimal level of diagnostic messages to display
    - **Type:** `DiagnoseLevel`
    - **ENV:** `NVIM_DIAGNOSE_LEVEL`
    - **Defaults:** `'hint'`

  - _`diagnose_mode`_ — diagnose display level.
    options are `'inline'|'detailed'|'pretty'`, `inline` means use virtual text
    to display diagnostic messages, `detailed` means use extra virtual lines,
    `pretty` means use extra plugin -- `tiny-inline-diagnostic` to display
    - **Type:** `DiagnoseMode`
    - **ENV:** `NVIM_DIAGNOSE_MODE`
    - **Defaults:** `'inline'`

  - _`diagnose_with_fancy_underline`_ — use fancy curl underline. **need terminal and tmux support**
    - **Type:** `boolean`
    - **ENV:** `NVIM_DIAGNOSE_WITH_FANCY_UNDERLINE`
    - **Defaults:** `false`

  - _`enable_current_line_blame`_ — enable virtual text line blame at the end of line
    - **Type:** `boolean`
    - **ENV:** `NVIM_ENABLE_CURRENT_LINE_BLAME`
    - **Defaults:** `false`

  - _`enable_relative_lnum`_ — use relative number
    - **Type:** `boolean`
    - **ENV:** `NVIM_ENABLE_RELATIVE_LNUM`
    - **Defaults:** `false`

  - _`enable_sticky_buffer`_ — enable sticky buffer for each window
    - **Type:** `boolean`
    - **ENV:** `NVIM_ENABLE_STICKY_BUFFER`
    - **Defaults:** `false`

  - _`statline_scrollbar_style`_ — heirline scroll bar style, which displays cursor position
    - **Type:** `StatusScrollbarStyle`
    - **ENV:** `NVIM_STATLINE_SCROLLBAR_STYLE`
    - **Defaults:** `'moon'`

  - _`transparent_mode`_ — enable transparent mode
    - **Type:** `boolean`
    - **ENV:** `NVIM_TRANSPARENT_MODE`
    - **Defaults:** `false`

- Workspace
  - _`allow_workspace_patch`_ — allow editor patch its behavior according to workspace config
    - **Type:** `boolean`
    - **ENV:** `NVIM_ALLOW_WORKSPACE_PATCH`
    - **Defaults:** `false`

  - _`workspace_patch_always_restrict`_ — always enable restrict mode, disable _dofile_ to prevent **ACE**
    - **Type:** `boolean`
    - **ENV:** `NVIM_WORKSPACE_PATCH_ALWAYS_RESTRICT`
    - **Defaults:** `true`

<!-- enddoc@profile -->

> [!NOTE]
>
> Environment variables are still available. They have higher priority than JSON configured values.

## Maybe wanted features

- Markdown Table Format

- Image preview in markdown(Partly support)

- Search enhance

- Fold range highlighting on unfolding

- AsciiMode -- No nerd font

## TODO List

- Latex preview

- Collect assets and remove some hard coded options

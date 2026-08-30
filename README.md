<p align="center">
  <h2 align="center">Yet Another Nvim Config</h2>
</p>

<p align="center">A <b>Modular & High-performance</b> set of configurations for Nvim which is written all <b><i>by hand</i></b></p>

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

## Why this is different

Most configs are a list of plugins plus options. This one is **tuned around a workflow**:

- **Configurable as data, not code.** A single `nvimrc.json` plus env vars drive everything — features, languages, diagnostics. No hunting through Lua.
- **Fewer plugins, hand-tuned behavior.** Notifications, messages, the command line, tabs, and sessions are reimplemented from scratch to fit this workflow.

Plus the usual — completion, fuzzy finder, Treesitter, LSP, formatting, statusline. Nothing exotic to list.

## Showcase

![Dashboard](./doc/img/Dashboard.webp)

![Workspace](./doc/img/Workspace.webp)

## Requirements

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

> [!CAUTION]
>
> This configuration only work for **nvim >= 0.12**

## Try it now

You can try it immediately without replacing your origin configurations.

```bash
./venv # Launch a virtual env shell, it's actually a sanbox shell that isolates plugins, cache and runtime file

nvim     # Launch neovim on this config, without making changes to your ~/.local/share
```

Or, you may download the repo to `~/.config/<name>`, and run `NVIM_APPNAME=<name> nvim` to launch

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

## License [MIT](./LICENSE)

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

##  Showcase 

![Dashboard](./doc/img/Dashboard.png)

![Workspace](./doc/img/Workspace.png)

## Feature

- Modular Profile System: Switch between different configuration profiles seamlessly. Customize editor behavior on
  different device/os just by modify a json table.

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

##  Try it now 

You can try it immediately without replacing your origin configurations.

```bash
./venv # Launch a virtual env shell, it's actually a sanbox shell that isolates plugins, cache and runtime file

nvim     # Launch neovim on this config, without make changes to your ~/.local/share
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
- [x] Json-env combined profile system

## Optional features

Some features are optional, controlled by a json file -- `nvimrc.json`, this file should be placed under your config
dir. Here're customizable items:

- UI
  - _`transparent_mode`_ enable transparent mode
  - _`dashboard_art_name`_ choose an ascii art on dashboard
  - _`statline_scrollbar_style`_ choose a style for heirline scroll bar, which displays cursor position
  - _`enable_relative_lnum`_ use relative number
  - _`diagnose_mode`_ diagnose display level, options are `'inline'|'detailed'|'pretty'`, `inline` means use virtual text
    to display diagnostic messages, `detailed` means use extra virtual lines, `pretty` means use extra plugin --
    `tiny-inline-diagnostic` to display, default `inline`
  - _`diagnose_level`_ minimal level of diagnostic messages to display
  - _`diagnose_with_fancy_underline`_ whether to use fancy undercurl line, **need terminal and tmux support**
  - _`enable_current_line_blame`_ enable virtual text line blame at the end of line
  - _`enable_dropbar`_ enable breadcrumbs for each window
  - _`use_ufo_as_fold_provider`_ use `nvim-ufo` as fold provider to get better code fold experience

- Lang module
  - _`lang_blacklist`_ disabled lang configs, default none, split by ','
  - _`lang_whitelist`_ enabled lang configs, default all, split by ','
  - _`lang_levels`_ lang feature config, syntax: string `c:full;cpp:none;rust:lsp,+ts,-fmt` means enable full
    feature for c, disable all features for cpp, enable tree-sitter and lsp, disable formatter for rust.

- Lsp
  - _`enable_lsp`_ enable lsp **Disable LSP if nvim version <= 0.11**
  - _`enable_inlay_hint`_ default enable lsp inlay hint if has capability
  - _`use_emmylua_ls`_ use `emmylua_ls` as lua language server
  - _`workspace_inject_plugin_path`_ inject plugin path to `emmylua_ls` workspace config
  - _`workspace_inject_vim_rt`_ inject vim runtime to `emmylua_ls` workspace config
  - `clang_format_path` assign `clang-format` binary path
  - `clangd_path` assign `clangd` binary path

- BigFile
  - _`bigfile_size_byte`_ average byte size
  - _`bigfile_size_line`_ average line length (useful for minified files)

- Workspace
  - _`allow_workspace_patch`_ allow editor patch its behavior according to workspace config
  - _`workspace_patch_always_restrict`_ always enable restrict mode, disable _dofile_ to prevent **ACE**

- Misc
  - _`sandbox_mode`_ control sanbox features `sesson|undo|shada|swap|wb`, `wb` for writebackup
  - _`disable_im_switch`_ disable auto im switcher
  - _`blink_use_binary`_ use prebuild binary instead of building
  - _`integrated_terminal_shell`_ choose integrated terminal shell, default zsh

Here are defaults:

```lua
local defaults = {
  sandbox_mode = 'none', -- experimental sandbox mode
  transparent_mode = false,
  diagnose_mode = 'inline', -- 'inline'|'detailed'|'pretty'
  diagnose_level = 'hint', -- 'hint'|'info'|'warn'|'error'
  diagnose_with_fancy_underline = false,
  dashboard_art_name = 'Ayanami Rei',
  workspace_inject_vim_rt = true,
  workspace_inject_plugin_path = false,
  use_emmylua_ls = false,
  use_ufo_as_fold_provider = false,
  disable_im_switch = false,
  enable_lsp = vim.fn.has 'nvim-0.11' == 1,
  enable_inlay_hint = false,
  enable_current_line_blame = false,
  enable_relative_lnum = false,
  blink_use_binary = true,
  lang_blacklist = 'all',
  lang_whitelist = '',
  lang_levels = '',
  statline_scrollbar_style = 'moon',
  bigfile_size_byte = 2097152, -- 2MB
  bigfile_size_line = 100000,
  allow_workspace_patch = false,
  workspace_patch_always_restrict = true,
  enable_dropbar = false,
  clang_format_path = 'clang-format',
  clangd_path = 'clangd',
  integrated_terminal_shell = 'zsh',
}
```

> [!NOTE]
>
> Environment variables are still available. They have higher priority than json configured values.

## Maybe wanted features

- Markdown Table Format

- Image preview in markdown(Partly support)

- Search enhance

- Fold range highlighting on unfolding

- AsciiMode -- No nerd font

## TODO List

- Latex preview

- Collect assets and remove some hard coded options

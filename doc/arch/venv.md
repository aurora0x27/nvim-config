# Debug shell

The `venv` script opens an isolated sandbox shell for running this config without
touching the real `~/.config/nvim`. That real config is production: it is rarely
edited directly. Changes are made on a copy of the source and tested in the sandbox.

## Why it exists

The sandbox is what makes the current complexity survivable:

- **Isolation.** A broken config inside the sandbox does not corrupt production.
  Plugins, cache, bytecode, sessions, and logs written through `stdpath` land in
  the repo's `nvim-cache/` directory (gitignored), never in
  `~/.local/share/nvim`. See [Limitations](#limitations) for what stays outside
  the sandbox.
- **Safe rewrites.** Complex subsystems can be rebuilt wholesale. The ui-events
  subsystem — which hijacks `vim.ui_attach` and reimplements message routing — would
  be nearly impossible to debug without it.
- **Plugin upgrades.** Trying a new plugin version or a replacement is a sandbox run,
  not a production gamble.

It was originally built for isolated debugging in the early days, before the
current sandbox workflow existed. It is now the standard workflow for feature
work, refactors, and upgrades.

## How it works

Isolation happens at three levels:

1. `venv` wraps `nvim` so it launches with `--clean -u <repo>/init.lua` — ignoring
   the user config and loading only this one. `--clean` also implies `-i NONE`, so
   no ShaDa is read or written.
2. `init.lua` detects debug mode (`NVIM_CONFIG_DEV=1`) and replaces the Lua-facing
   `vim.fn.stdpath`, so Lua code resolving `config`, `data`, `state`, `log`, `run`,
   `config_dirs` and `data_dirs` stays under `nvim-cache/`. This runs before
   `vim.loader` is enabled, so bytecode caching is covered too.
3. Neovim resolves its option defaults before `init.lua` runs, so the debug block
   also creates and points `directory`, `undodir` and `backupdir` at
   `nvim-cache/state/{swap,undo,backup}`. Without this, swap, undo and backup
   files would be shared with the production state directory.

If `persist_local_mode` enables swap, undo or `wb`, `persist.setup()` later
moves those directories into the workspace's `.cache/nvim`; that is intentional
and still outside the production state.

## Usage

```sh
./venv    # enter the sandbox shell (fish)
nvim      # launch the sandboxed nvim
exit      # leave; all state remains in nvim-cache/

./venv -h                                   # show help
./venv -sh zsh                              # use zsh instead of fish
./venv -sh zsh -prof-count 50 -prof-warmup 2  # customize startup profiling
NVIM_BINARY=/absolute/path/to/nvim ./venv   # use a specific binary
```

| option           | default | purpose                            |
| ---------------- | ------- | ---------------------------------- |
| `-sh`, `--shell` | `fish`  | shell to launch (`fish` or `zsh`)  |
| `-prof-count`    | `100`   | iteration count for `prof-startup` |
| `-prof-warmup`   | `3`     | warmup runs for `prof-startup`     |
| `-h`, `--help`   |         | print help and exit                |

`nvim` and `prof-startup` are available inside the shell in both fish and zsh.
`prof-startup` requires the `vim-startuptime` binary. `NVIM_BINARY` overrides the
binary and must be an absolute path (`~` is expanded). Nesting `./venv` inside
itself is rejected.

## Environment

| variable                      | purpose                                                                                             |
| ----------------------------- | --------------------------------------------------------------------------------------------------- |
| `NVIM_CONFIG_DEV_CONFIG_ROOT` | repo root — the sandboxed config source                                                             |
| `NVIM_CONFIG_DEV_CACHE_ROOT`  | `nvim-cache/`, split into `share/`, `state/` (swap, undo, backup, logs, sessions), `cache/`, `run/` |
| `NVIM_CONFIG_DEV_BINARY`      | resolved binary, forced absolute                                                                    |
| `VIRTUAL_ENV`                 | sentinel reused to reject nested shells                                                             |

Sandbox state lives under `nvim-cache/`, and `stdpath('config')` points at the
repo root. Workspace-local persistence (when enabled) writes to the workspace's
`.cache/nvim` by design. Paths that still escape the sandbox are listed under
Limitations. On launch, `venv` prints a summary of the resolved config root,
cache root, binary, shell, and profiling settings. Guard errors cover a missing
binary, a non-absolute `NVIM_BINARY`, unsupported shells, invalid numeric
options, and nested shells.

## Limitations

The sandbox is a Lua-level path shadow, not an OS-level sandbox.

- **Vimscript is not redirected.** The builtin `stdpath()` used by Vimscript
  resolves from the process environment, so Vimscript plugins and hard-coded
  `~/.config/nvim` / `~/.local/share/nvim` paths still reach production data.
  The builtin cannot be shadowed from Lua (`function! stdpath()` is rejected
  with `E128`). Setting `vim.env.XDG_*` inside the debug block would redirect it
  — `stdpath()` is computed on every call — but `vim.env` is the real process
  environment: every child nvim spawns inherits it (LSP servers, `git`,
  `:terminal`), and changing `XDG_CONFIG_HOME` breaks tools that read their own
  config. The config therefore leaves the environment untouched and accepts
  this gap.
- **`nvim.log` is not redirected.** Neovim opens it before `init.lua` runs, so
  it always goes to the real `stdpath('log')`. Only `$NVIM_LOG_FILE` or
  `XDG_STATE_HOME` set before launching `nvim` can move it; `venv` sets
  neither.
- **ShaDa safety depends on `--clean`.** Entering debug mode by exporting
  `NVIM_CONFIG_DEV=1` without `--clean` would read and write the real ShaDa.
  Always launch through `venv`.
- **Unknown `stdpath` keys return `nil`.** The shadow covers only the keys in
  its own table and does not raise Neovim's `E6100`, so an invalid key fails
  later at the call site instead.

# Debug shell

The `venv` script opens an isolated sandbox shell for running this config without
touching the real `~/.config/nvim`. That real config is production: it is rarely
edited directly. Changes are made on a copy of the source and tested in the sandbox.

## Why it exists

The sandbox is what makes the current complexity survivable:

- **Isolation.** A broken config inside the sandbox can never corrupt production.
  Plugins, cache, bytecode, session, and logs all land in the repo's `nvim-cache/`
  directory (gitignored), never in `~/.local/share/nvim`.
- **Safe rewrites.** Complex subsystems can be rebuilt wholesale. The ui-events
  subsystem — which hijacks `vim.ui_attach` and reimplements message routing — would
  be nearly impossible to debug without it.
- **Plugin upgrades.** Trying a new plugin version or a replacement is a sandbox run,
  not a production gamble.

It was originally built for isolated debugging in the early days, before the config
could reload itself. It is now the standard workflow for feature work, refactors,
and upgrades.

## How it works

Isolation happens at two levels:

1. `venv` wraps `nvim` so it launches with `--clean -u <repo>/init.lua` — ignoring
   the user config and loading only this one.
2. `init.lua` detects debug mode (`NVIM_CONFIG_DEV=1`) and redefines `vim.fn.stdpath`
   so every path (`config`, `data`, `state`, `log`, `run`) is redirected under
   `nvim-cache/`.

The `stdpath` redefinition happens before `vim.loader` is enabled, so bytecode
caching also stays inside the sandbox.

## Usage

```sh
./venv    # enter the sandbox shell (zsh)
nvim      # launch the sandboxed nvim
exit      # leave; all state remains in nvim-cache/

NVIM_BINARY=/absolute/path/to/nvim ./venv   # use a specific binary
./venv --fish                                # fish instead of zsh
```

`nvim` is aliased inside the shell. `NVIM_BINARY` overrides the binary and must be
an absolute path (`~` is expanded). Nesting `./venv` inside itself is rejected.

## Environment

| variable                      | purpose                                                        |
| ----------------------------- | -------------------------------------------------------------- |
| `NVIM_CONFIG_DEV_CONFIG_ROOT` | repo root — the sandboxed config source                        |
| `NVIM_CONFIG_DEV_CACHE_ROOT`  | `nvim-cache/`, split into `share/`, `state/`, `cache/`, `run/` |
| `NVIM_CONFIG_DEV_BINARY`      | resolved binary, forced absolute                               |
| `VIRTUAL_ENV`                 | sentinel reused to reject nested shells                        |

There is no state beyond `nvim-cache/`; the shell only prints a `[Note]` banner and
guard errors (missing binary, non-absolute `NVIM_BINARY`).

# Design

This config makes a few deliberate, sometimes counterintuitive choices. They are
the point of the config, not accidents. This document explains the "why"; per-subsystem
details live in their own files under `doc/arch/`.

## nvim is a short-lived process

In this config, nvim is not treated as a daemon you keep alive — it's an editing task
spawned by a workspace. This single assumption drives most of the design:

- **State is externalized, not accumulated.** Everything that matters is written to
  disk: sessions, undo history, shaDa, swap files, and the buffer-pool layout
  (which tab holds which buffers). Memory is a scratchpad, not the source of truth.
- **Startup is cheap on purpose.** Bytecode is cached (`vim.loader`), the runtimepath
  is reset to a minimal set, and plugins load lazily. Restart is the recovery
  mechanism, so it must be fast and lossless.
- **The sanctioned loop** is: open nvim at the workspace root → do work → quit.
  The next launch reconstructs the working set from disk.

This is the opposite of the "emacs daemon" model — a long-lived server you reconnect
to. Here the process is disposable; persistence replaces longevity.

## cwd is the identity

The startup cwd defines the workspace. It is read once and treated as immutable:

- Session layout, workspace-local persistence, the workspace patch, and some LSP
  project roots are all keyed off the process cwd.
- **Switching cwd (`:cd/:tcd/:lcd`) is undefined behavior.** Nothing errors loudly; instead,
  every subsystem that captured the original cwd silently points at the wrong place.
- Need another context? Open nvim from that directory — don't move the process,
  start a new one.

A corollary: the config never relies on window-local or tab-local cwd. The process
cwd is the single anchor.

## No hot reload

Configuration is resolved once at startup, then treated as immutable runtime metadata:

- `Profile` rejects writes after `setup()`; `Lang` resolves feature flags once;
  subsystems guard against double initialization.
- There is no reload facility on purpose. "Reloading" is a workaround for editors
  too expensive to restart — which this config deliberately is not.
- Changed the config? Quit and reopen. That is the supported path, and it is fast.

Hot reload and cwd switching are the two operations this config explicitly refuses
to support, for the same reason: they reintroduce mutable, hard-to-reason-about
state into a design built around deterministic, restart-from-disk reconstruction.

## Data-driven, not imperative

Policy ("what to enable") is separated from implementation ("how a plugin is set up"):

- `lua/core/profile/` resolves editor behavior from `nvimrc.json` + environment
  variables, validated against a schema and merged with fixed precedence
  (ENV > JSON > defaults).
- `lua/core/lang/` turns language capability declarations into concrete lists —
  which LSPs to install, which Treesitter parsers, which formatters map to which
  filetype.
- Plugins consume this resolved data (`Lang.get_*()`, `Profile.*`); they never make
  decisions on their own. Adding a language or an option is a data change, not a
  code change.

The schema itself is generated: `assets/manifest.lua` is the single source of truth,
from which defaults, types, and documentation are produced (`make autogen`). Adding
a new option means editing one file.

## The editor as an SDK

The long-term direction is to expose the runtime as an API rather than a wall of
plugin configs:

- Runtime globals (`Profile`, `Lang`, `Bus`) are the current API surface — other code
  queries them instead of reading env vars or JSON directly.
- The workspace patch (`.nvim` / `.vscode/nvim`) is a per-project extension point,
  guarded by a trust model to avoid arbitrary code execution.
- A self-hosted module loader is in progress, aiming to replace the plugin manager
  with a scheme/provider abstraction (where a module comes from vs. how it's fetched).

This part is still aspirational rather than settled; the rest of the config already
reflects it.

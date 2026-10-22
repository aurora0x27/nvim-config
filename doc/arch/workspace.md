# Workspace patch

A workspace can extend the editor from a local patch directory:

- `.nvim/` is preferred.
- `.vscode/nvim/` is the fallback.

Both are resolved from the immutable process cwd. If both exist, `.nvim` wins.
The workspace patch is not discovered from parent directories.

## Configuration

If `<patch>/nvimrc.json` exists, it is merged into `Profile` after the user-level
`nvimrc.json` and before environment variables. The effective precedence is:

```text
ENV > workspace nvimrc.json > user nvimrc.json > defaults
```

This means a workspace can override user-level values for the current workspace.
Unknown keys produce warnings; type mismatches reject the workspace file.

`allow_workspace_patch` controls the executable part of the patch:

| effective value | behavior                                                                    |
| --------------- | --------------------------------------------------------------------------- |
| `false`         | `nvimrc.json` is still merged, but no runtime directory is added to the rtp |
| `true`          | the patch directory and its `after/` subtree are added to lazy's rtp        |

Because the workspace file is merged into `Profile`, a workspace can set
`allow_workspace_patch = true` itself. There is no trust database, hash, confirm
prompt, or ignore list. The user-level value is a default, not a hard deny: only
open workspaces whose patch code you trust.

When `allow_workspace_patch` is `false`, the workspace patch cannot execute code,
but its `nvimrc.json` values still participate in profile resolution. Some
profile values point at external binaries or storage locations, so "no patch
code" is not the same as "no external effects".

## Runtime layout

With the patch directory on the rtp, the normal Neovim runtime rules apply:

| path                                                           | loading                                         |
| -------------------------------------------------------------- | ----------------------------------------------- |
| `plugin/`                                                      | sourced by lazy at startup                      |
| `ftdetect/`                                                    | sourced by lazy at startup                      |
| `after/plugin/`                                                | sourced after all regular `plugin/` directories |
| `lua/`                                                         | available through `require`                     |
| `ftplugin/`                                                    | sourced on `FileType`                           |
| `after/ftplugin/`                                              | sourced after regular `ftplugin/` files         |
| `lsp/`, `queries/`, `parser/`, `syntax/`, `indent/`, `colors/` | resolved through the rtp                        |

`<patch>/after` is added only when it exists. It is appended after the patch
directory, so it has the last word for `after/plugin` and `after/ftplugin`.
The patch directory itself is appended rather than prepended: it can add runtime
files and use `after/` to override, but it cannot replace the config's own core
modules by shadowing them.

## No init.lua

A workspace `init.lua` is no longer executed. If one is present, startup emits a
warning and ignores it. Use ordinary runtime files instead:

- `plugin/` for setup that should run at startup;
- `after/plugin/` for setup that must run after other plugins;
- `ftplugin/` or `after/ftplugin/` for filetype-specific behavior.

Patch scripts run during lazy's startup, before the `LazyVimStarted` and
`VeryLazy` autocmds. If a patch needs a fully initialized editor, register a
`User LazyVimStarted` or `User VeryLazy` autocmd inside the patch.

The old `trusted_workspaces` and `ignored_workspaces` files under
`stdpath("data")` are no longer read and can be removed.

## Statusline

The workdir component uses `allow_workspace_patch` as a coarse indicator: the
unlocked icon means the feature is enabled, the locked icon means it is disabled.
It is not a per-workspace trust indicator.

## Scope

Use the workspace patch for runtime extensions such as project-local ftplugins,
linters, or LSP configuration. Basic editor behavior such as indentation and
line endings belongs in `.editorconfig`; the workspace patch should not be the
first tool for those settings.

Workspace patch code executes with the same permissions as the editor. Do not
enable it globally and then open untrusted repositories.

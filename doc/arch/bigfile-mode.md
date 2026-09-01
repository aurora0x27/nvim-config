# Bigfile mode

Bigfile mode is not a module. It is the emergent behavior of a few scattered fragments.
It accelerates file loading and disables most high-cost features.

## How it works

The detection is triggered on `BufReadPost`. It creates a fake filetype `bigfile` to disable
most filetype related high cost features, and set a `vim.b.bigfile`.

## The threshold

`is_bigfile()` (`lua/utils/detect.lua`) compares against two Profile options,
overridable through `nvimrc.json` or `NVIM_BIGFILE_SIZE_*` environment variables:

| option              | default   | meaning                                               |
| ------------------- | --------- | ----------------------------------------------------- |
| `bigfile_size_line` | `100000`  | big when the file has more lines than this            |
| `bigfile_size_byte` | `2097152` | ...or more bytes than this (byte count of the buffer) |

Line count and byte size are OR-ed, so both minified files (few lines, many bytes)
and log dumps (many lines) are caught.

## Why a fake filetype

Most expensive features are gated on `FileType`: parser startup, per-filetype
plugins, formatting. Pointing the buffer at a filetype with no such machinery avoids
most of them in one stroke; the handlers that fire before the switch are opted out
individually.

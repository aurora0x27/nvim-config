---@brief
---
--- https://github.com/EmmyLuaLs/emmylua-analyzer-rust
---
--- Emmylua Analyzer Rust. Language Server for Lua.
---
--- `emmylua_ls` can be installed using `cargo` by following the instructions[here]
--- (https://github.com/EmmyLuaLs/emmylua-analyzer-rust?tab=readme-ov-file#install).
---
--- The default `cmd` assumes that the `emmylua_ls` binary can be found in `$PATH`.
--- It might require you to provide cargo binaries installation path in it.
---@type vim.lsp.Config
local emmylua_ls = {
  cmd = { 'emmylua_ls' },
  filetypes = Lang.lsp_get_ft 'emmylua_ls',
  root_dir = require 'utils.fs'.cwd(),
  workspace_required = false,
}

return emmylua_ls

---@brief
---
--- https://pyrefly.org/
---
---`pyrefly`, a faster Python type checker written in Rust.
--
-- `pyrefly` is still in development, so please report any errors to
-- our issues page at https://github.com/facebook/pyrefly/issues.

---@type vim.lsp.Config
local Pyrefly = {
  cmd = { 'pyrefly', 'lsp' },
  filetypes = Lang.lsp_get_ft 'pyrefly',
  root_dir = require 'utils.fs'.cwd(),
  on_exit = function(code, _, _)
    vim.schedule(function()
      vim.notify(
        'Closing Pyrefly LSP exited with code: ' .. code,
        vim.log.levels.INFO
      )
    end)
  end,
}

return Pyrefly

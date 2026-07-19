--------------------------------------------------------------------------------
-- Sandbox options
--
-- Options:
--   * session  persistance.nvim
--   * undo     undofile
--   * shada    shared data, ShaDa file
--   * swap     create swapfile for current buffer
--   * wb       writeback mode
--------------------------------------------------------------------------------
local M = {}

local SANDBOX_MODE_DEFAULT = {
  session = false,
  undo = false,
  shada = false,
  swap = false,
  wb = false,
}

local Mask = require 'utils.featstr'.parse(
  Profile.sandbox_mode,
  SANDBOX_MODE_DEFAULT,
  function(msg)
    require 'utils.misc'.error(msg, { title = 'Sandbox option' })
  end
)

function M.get_mask()
  return Mask
end

return M

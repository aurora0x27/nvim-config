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

local log = require 'utils.logger'.new 'Sandbox'

local Mask = require 'utils.featstr'.parse(
  Profile.sandbox_mode,
  SANDBOX_MODE_DEFAULT,
  function(msg)
    log.error(msg)
  end
)

function M.get_mask()
  return Mask
end

return M

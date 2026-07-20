--------------------------------------------------------------------------------
-- Logger Module
--
-- Provides module-scoped logging utilities.
--
-- Each subsystem should create its own logger instance with a stable title:
--
--     local log = require 'utils.logger'.logger(LOG_TITLE)
--
-- The logger provides a unified entry point for diagnostic messages and
-- formats messages using string.format before forwarding them to the Neovim
-- notification system.
--
-- Keeping logging behind this abstraction allows the notification backend
-- (currently vim.notify, routed through Bus) to evolve without requiring
-- changes across the codebase.
--
-- Usage:
--
--     local LOG_TITLE = 'Profile Module'
--     local log = require 'utils.logger'.logger(LOG_TITLE)
--
--     log.info('Loaded config: %s', path)
--     log.warn('Unknown option: %s', key)
--     log.error('Failed to parse file')
--
-- The logger title should represent the owning module rather than a temporary
-- message category. This keeps logs consistent with other module identifiers
-- such as augroups and namespaces.
--------------------------------------------------------------------------------
local M = {}

local sprintf = string.format

local Entries = {}

local function send(massage, lvl, opts)
  vim.notify(massage, lvl, opts)
end

---@class Logger
---@field info  fun(string,...)
---@field warn  fun(string,...)
---@field error fun(string,...)
---@field debug fun(string,...)
---@field trace fun(string,...)

---@param title string
---@return Logger
function M.new(title)
  if Entries[title] then
    return Entries[title]
  end
  ---@type Logger
  local ret = {
    info = function(fmt, ...)
      send(sprintf(fmt, ...), vim.log.levels.INFO, { title = title })
    end,
    warn = function(fmt, ...)
      send(sprintf(fmt, ...), vim.log.levels.WARN, { title = title })
    end,
    error = function(fmt, ...)
      send(sprintf(fmt, ...), vim.log.levels.ERROR, { title = title })
    end,
    debug = function(fmt, ...)
      send(sprintf(fmt, ...), vim.log.levels.DEBUG, { title = title })
    end,
    trace = function(fmt, ...)
      send(sprintf(fmt, ...), vim.log.levels.TRACE, { title = title })
    end,
  }
  Entries[title] = ret
  return ret
end

---@return string[]
function M.list_entries()
  return vim.tbl_keys(Entries)
end

return M

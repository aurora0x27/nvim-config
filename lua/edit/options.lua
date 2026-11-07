--------------------------------------------------------------------------------
-- This file contains options, which is executed after lazy initialization
--------------------------------------------------------------------------------
local M = {}

local detect = require 'utils.detect'
local LOG_TITLE = 'Options'
local log = require 'utils.logger'.new(LOG_TITLE)

local Opt = {
  numberwidth = 1,
  spell = false,
  signcolumn = 'auto',
  termguicolors = true,
  wildmenu = true,
  ignorecase = true,
  scrolloff = 5,
  virtualedit = 'block',
  showmode = false,
  cmdheight = 0,
  splitright = true,
  splitbelow = true,
  guicursor = 'n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,t:block-blinkon0-TermCursor',
  tabclose = 'uselast',
  confirm = true, -- confirm before quitting unsaved changes
}

local _initialized = false

function M.setup()
  if _initialized then
    log.error 'Should not initialize module twice'
    return
  end

  if detect.is_windows() then
    if detect.is_executable 'win32yank.exe' then
      vim.o.shell = 'nu'
      vim.o.shellcmdflag = '-c'
      vim.o.shellquote = ''
      vim.o.shellxquote = ''
      log.info 'Run windows clipboard settings'
      vim.g.clipboard = {
        name = 'win32yank',
        copy = {
          ['+'] = 'win32yank.exe -i --crlf',
          ['*'] = 'win32yank.exe -i --crlf',
        },
        paste = {
          ['+'] = 'win32yank.exe -o --lf',
          ['*'] = 'win32yank.exe -o --lf',
        },
        cache_enabled = 0,
      }
    else
      log.warn 'Cannot find win32yank.exe, please install'
    end
  end

  vim.fn.mkdir(vim.opt.undodir:get()[1], 'p')

  for k, v in pairs(Opt) do
    vim.o[k] = v
  end
  _initialized = true
end

return M

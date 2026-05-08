--------------------------------------------------------------------------------
-- Preload Module
--
-- This file contains settings to load before initializing lazy
--------------------------------------------------------------------------------
local M = {}

function M.setup()
  -- set global leader
  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '

  local alpha = function()
    return string.format('%x', math.floor(255 * (vim.g.transparency or 0.8)))
  end

  -- set global transparent_mode
  if Profile.transparent_mode and vim.g.neovide then
    vim.g.neovide_window_blurred = true
    vim.g.neovide_opacity = 0.9
    vim.g.neovide_normal_opacity = 0.8
    vim.g.neovide_background_color = '#1e1e2e' .. alpha()
    vim.g.neovide_floating_corner_radius = 0.3
  end

  -- WARN: put this line here instead of `options.lua`
  -- prevents line number and cursor line appear on
  -- dashboard, so werid.
  vim.o.number = true
  vim.o.relativenumber = Profile.enable_relative_lnum
  vim.o.cursorline = not Profile.transparent_mode

  vim.opt.fillchars = {
    eob = ' ',
    diff = '╱',
    foldopen = '',
    foldclose = '',
    foldsep = '▕',
    fold = ' ',
  }

  -- Will be covered by ftplugin
  vim.o.tabstop = 4
  vim.o.shiftwidth = 4
  vim.o.expandtab = true
  vim.o.autoindent = true
  vim.o.shada = require 'core.sandbox'.get_mask().shada and [[!,'100,<50,s10,h]]
    or ''

  -- filetype alias
  vim.filetype.add({
    extension = {
      mdx = 'markdown',
      tmpl = function(path)
        return path:match('%.([%w_]+)%.tmpl$') or 'template'
      end,
    },
    pattern = {
      ['xmake.lua'] = 'xmake',
    },
  })

  -- register new filetypes
  vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
    once = true,
    callback = function(_)
      vim.treesitter.language.register('lua', 'xmake')
    end,
  })

  vim.api.nvim_create_autocmd('BufReadPost', {
    ---@param arg vim.api.keyset.create_autocmd.callback_args
    callback = function(arg)
      local buf = arg.buf
      if require 'utils.detect'.is_bigfile(buf) then
        vim.b[buf].bigfile = true
        vim.bo.undofile = false
        vim.bo.swapfile = false
        vim.api.nvim_create_autocmd('FileType', {
          buffer = buf,
          once = true,
          callback = function()
            vim.defer_fn(
              require 'utils.loader'.bind(
                require 'utils.misc'.info,
                'Large file detected, some features are disabled'
              ),
              1000
            )
          end,
        })
        vim.cmd 'syntax off'
        vim.bo.filetype = 'bigfile'
      end
    end,
  })
end

return M

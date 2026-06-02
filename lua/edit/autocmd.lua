--------------------------------------------------------------------------------
-- Define some behaviors
--------------------------------------------------------------------------------
local M = {}

local AUG = vim.api.nvim_create_augroup('UserCustomed', { clear = true })
local CWD
local summary = require 'utils.fs'.summary

function M.setup()
  -- Highlight yanked text
  vim.api.nvim_create_autocmd('TextYankPost', {
    pattern = '*',
    group = AUG,
    callback = function()
      vim.highlight.on_yank {
        higroup = 'IncSearch',
        timeout = 200,
      }
    end,
  })

  vim.api.nvim_create_autocmd('BufReadPost', {
    group = AUG,
    callback = function(ev)
      if not CWD then
        CWD = vim.fn.getcwd()
      end

      local buf = ev.buf
      -- don't trigger warning on help.txt
      if vim.bo[buf].buftype == 'help' then
        return
      end

      local path = vim.api.nvim_buf_get_name(buf)
      if vim.startswith(path, 'oil://') then
        return
      end

      if #path > 0 and not vim.startswith(path, CWD) then
        vim.notify(
          '# Jump out of workspace\n*`'
            .. summary(path, 40, 20, 20)
            .. '`* is not in current workspace',
          vim.log.levels.WARN,
          { ft = 'markdown' }
        )
      end
    end,
  })

  vim.api.nvim_create_autocmd('BufReadPost', {
    group = AUG,
    callback = function(ev)
      -- don't set cursor on help.txt
      if vim.bo[ev.buf].buftype == 'help' then
        return
      end
      local mark = vim.api.nvim_buf_get_mark(0, '"')
      local lcount = vim.api.nvim_buf_line_count(0)
      if mark[1] > 0 and mark[1] <= lcount then
        vim.api.nvim_win_set_cursor(0, mark)
      end
    end,
    desc = 'Set cursor to the position where it was last left.',
  })

  vim.api.nvim_create_autocmd('ModeChanged', {
    group = AUG,
    pattern = { '*:[vV\x16]*', '*:[sS\x13]*' },
    callback = function()
      vim.diagnostic.enable(false)
    end,
  })

  vim.api.nvim_create_autocmd('ModeChanged', {
    group = AUG,
    pattern = { '[vV\x16]:*', '[sS\x13]:*' },
    callback = function()
      local new_mode = vim.v.event['new_mode']
      if
        new_mode
        and not (new_mode:find('[vV\x16]') or new_mode:find('[sS\x13]'))
      then
        vim.diagnostic.enable(true)
      end
    end,
  })

  -- close some filetypes with <q>
  vim.api.nvim_create_autocmd('FileType', {
    group = AUG,
    pattern = {
      'PlenaryTestPopup',
      'checkhealth',
      'dap-float',
      'dbout',
      'gitsigns-blame',
      'help',
      'lspinfo',
      'notify',
      'qf',
      'spectre_panel',
      'startuptime',
      'tsplayground',
      'msg',
      'pager',
      'dialog',
    },
    callback = function(event)
      vim.bo[event.buf].buflisted = false
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(event.buf) then
          return
        end
        vim.keymap.set('n', 'q', function()
          vim.cmd('close')
          pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
        end, {
          buf = event.buf,
          silent = true,
          desc = 'Quit buffer',
        })
      end)
    end,
  })

  vim.api.nvim_create_autocmd(
    'QuitPre',
    { group = AUG, callback = require 'core.bpm'.vacuum }
  )
end

return M

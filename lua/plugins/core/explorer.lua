--------------------------------------------------------------------------------
-- File system explorer
--------------------------------------------------------------------------------

local git_ignore_cache = {}

local function is_git_ignored(path)
  if git_ignore_cache[path] ~= nil then
    return git_ignore_cache[path]
  end
  local cmd = { 'git', 'check-ignore', '--quiet', path }
  local obj = vim.system(cmd, { text = true }):wait()
  local ignored = (obj.code == 0)
  git_ignore_cache[path] = ignored
  return ignored
end

---@type LazyPluginSpec
local MiniFiles = {
  'nvim-mini/mini.files',
  version = '*',
  lazy = true,
  opts = {
    -- Customization of shown content
    content = {
      -- Predicate for which file system entries to show
      filter = function(entry)
        if entry.name == '.git' then
          return false
        end

        return not is_git_ignored(entry.path)
      end,
      -- Highlight group to use for a file system entry
      highlight = nil,
      -- Prefix text and highlight to show to the left of file system entry
      prefix = nil,
      -- Order in which to show file system entries
      sort = nil,
    },

    -- Module mappings created only inside explorer.
    -- Use `''` (empty string) to not create one.
    mappings = {
      close = 'q',
      go_in = 'l',
      go_in_plus = 'L',
      go_out = 'h',
      go_out_plus = 'H',
      mark_goto = "'",
      mark_set = 'm',
      reset = '<BS>',
      reveal_cwd = '@',
      show_help = 'g?',
      synchronize = '=',
      trim_left = '<',
      trim_right = '>',
    },

    -- General options
    options = {
      -- Whether to delete permanently or move into module-specific trash
      permanent_delete = true,
      -- Whether to use for editing directories
      use_as_default_explorer = true,
    },

    -- Customization of explorer windows
    windows = {
      -- Maximum number of windows to show side by side
      max_number = math.huge,
      -- Whether to show preview of file/directory under cursor
      preview = false,
      -- Width of focused window
      width_focus = 50,
      -- Width of non-focused window
      width_nofocus = 15,
      -- Width of preview window
      width_preview = 25,
    },
  },
}

return MiniFiles

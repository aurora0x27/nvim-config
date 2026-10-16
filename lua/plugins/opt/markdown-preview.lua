local StdConfigDir = vim.fn.stdpath 'config'

-- install with yarn or npm
---@type LazyPluginSpec
local MarkdownPreview = {
  'aurora0x27/markdown-preview2.nvim',
  cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
  build = 'cd app && yarn install',

  config = function()
    require 'mkdp'.setup {
      -- open the preview automatically after entering a markdown buffer
      auto_start = false,
      -- close the preview when leaving the markdown buffer
      auto_close = true,
      -- only refresh on save / insert-leave instead of on every cursor move
      refresh_slow = false,
      -- make the commands available for every filetype
      command_for_global = false,
      -- filetypes that get the commands
      filetypes = { 'markdown' },

      -- server
      open_to_the_world = false, -- listen on 0.0.0.0 instead of 127.0.0.1
      open_ip = '', -- custom ip used to build the preview url
      port = nil, -- custom port, nil for a random one
      browser = '', -- browser command, '' for the system default
      browserfunc = nil, -- fun(url) to open the url yourself
      echo_preview_url = false, -- echo the preview url in the command line

      -- rendering
      page_title = '「${name}」', -- ${name} is replaced with the file name
      theme = 'dark', -- 'dark' / 'light', '' follows the OS
      markdown_css = StdConfigDir .. '/assets/mkdp_markdown.css', -- absolute path to a custom markdown css
      highlight_css = StdConfigDir .. '/assets//mkdp_highlight.css', -- absolute path to a custom highlight css
      images_path = nil, -- custom directory for local images

      -- combine several previews into a single browser window
      combine_preview = false,
      combine_preview_auto_refresh = true,

      preview_options = {
        mkit = {}, -- markdown-it options
        katex = {}, -- KaTeX options
        uml = {}, -- plantuml options
        maid = {}, -- mermaid options
        disable_sync_scroll = false,
        sync_scroll_type = 'middle', -- 'middle' | 'top' | 'relative'
        hide_yaml_meta = true,
        sequence_diagrams = {},
        flowchart_diagrams = {},
        content_editable = false,
        disable_filename = false,
        toc = {},
      },
    }
  end,

  ft = { 'markdown' },
}

return MarkdownPreview

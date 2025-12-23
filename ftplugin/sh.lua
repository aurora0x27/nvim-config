local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ''

if not (line:match '^#!.*/sh%s*$' or line:match '^#!.*/env%s+sh%s*$') then
    vim.api.nvim_set_option_value('filetype', 'bash', { buf = 0 })
end

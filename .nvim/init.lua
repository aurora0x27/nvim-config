-- Always use LF on windows in this repo
if vim.fn.has 'win32' == 1 then
    vim.opt.fileformats = { 'unix' }
    vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
        callback = function()
            vim.opt_local.fileformat = 'unix'
        end,
    })
end

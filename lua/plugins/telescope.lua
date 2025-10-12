-- Fuzzy finder

-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local focus_preview = function(prompt_bufnr)
    local action_state = require 'telescope.actions.state'
    local picker = action_state.get_current_picker(prompt_bufnr)
    local prompt_win = picker.prompt_win
    local previewer = picker.previewer
    local bufnr = previewer.state.bufnr or previewer.state.termopen_bufnr
    local winid = previewer.state.winid or vim.fn.win_findbuf(bufnr)[1]
    vim.keymap.set({ 'n', 'i' }, '<C-l>', function()
        vim.cmd(string.format('noautocmd lua vim.api.nvim_set_current_win(%s)', prompt_win))
    end, { buffer = bufnr })
    vim.cmd(string.format('noautocmd lua vim.api.nvim_set_current_win(%s)', winid))
    -- api.nvim_set_current_win(winid)
end

local Telescope = {
    'nvim-telescope/telescope.nvim',
    lazy = true,
    cmd = { 'Telescope' },
    opts = {
        defaults = {
            layout_config = {
                prompt_position = 'top',
            },
            sorting_strategy = 'ascending',
            file_ignore_patterns = {
                'logs',
                '%.root',
                '%.gif',
                '%.pdf',
                '%.png',
                '%.jpg',
                '%.jpeg',
                '%.vcxproj',
                '%.vcproj',
                '%.notes',
                '%.rst',
                '%.bat',
                '%.cmake',
                'Online.*%.xml',
            },
            mappings = {
                n = {
                    ['<C-l>'] = focus_preview,
                },
                i = {
                    ['<C-l>'] = focus_preview,
                },
            },
        },
    },
}

return Telescope

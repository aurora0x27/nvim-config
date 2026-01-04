---@type LazyPluginSpec
local LazyDev = {
    'folke/lazydev.nvim',
    ft = 'lua', -- only load on lua files
    opts = {
        library = {
            -- See the configuration section for more details
            -- Load luvit types when the `vim.uv` word is found
            { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
            {
                path = 'lazy.nvim',
                words = { 'Lazy.*Spec' },
            },
        },
        enabled = function(root_dir)
            if vim.g.lazydev_enabled == false then
                return false
            end

            -- Disable if .luarc.json exists and workspace.library is set
            local fd = vim.uv.fs_open(root_dir .. '/.luarc.json', 'r', 438)
            if fd then
                local luarc = vim.json.decode(assert(vim.uv.fs_read(fd, vim.uv.fs_fstat(fd).size)))
                return not (luarc.workspace and luarc.workspace.library)
            end
            return true
        end,
    },
}

return LazyDev

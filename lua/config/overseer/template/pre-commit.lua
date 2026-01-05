local function get_precommit_cfg(opts)
    return vim.fs.find({ '.pre-commit-config.yaml', '.pre-commit-config.yml' }, { upward = true, path = opts.dir })[1]
end

---@type overseer.TemplateFileProvider
return {
    name = 'RunPrecommitHook',

    cache_key = function(opts)
        return get_precommit_cfg(opts)
    end,

    generator = function(opts, cb)
        if vim.fn.executable 'pre-commit' == 0 then
            return cb 'Binary `pre-commit` not found'
        end

        local cfg = get_precommit_cfg(opts)
        if not cfg then
            return cb 'No pre-commit config found'
        end

        local cwd = vim.fs.dirname(cfg)

        cb {
            {
                name = 'pre-commit run --all-files',
                builder = function()
                    return {
                        cmd = { 'pre-commit', 'run', '--all-files' },
                        cwd = cwd,
                    }
                end,
            },
        }
    end,
}

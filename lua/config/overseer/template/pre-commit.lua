return {
    name = 'RunPreCommitTmpl',
    generator = function()
        local cond = function()
            local has_cfg = vim.fn.filereadable(vim.fn.getcwd() .. '/.pre-commit-config.yaml') == 1
                or vim.fn.filereadable(vim.fn.getcwd() .. '/.pre-commit-config.yml') == 1
            local has_binary = vim.fn.executable 'pre-commit'
            if has_binary and has_cfg then
                return true
            elseif not has_binary then
                return false, 'Binary `pre-commit` not found'
            end
            return false
        end

        local ok, msg = cond()
        if ok then
            local tmpl = {
                name = 'run precommit hook',
                builder = function()
                    return {
                        cmd = { 'pre-commit', 'run', '--all-files' },
                        name = 'Run precommit',
                        cwd = vim.fn.getcwd(),
                    }
                end,
            }
            -- IMPORTANT: must return a list of templates
            return { tmpl }
        else
            -- correct: return string for error, or nil
            return msg or nil
        end
    end,
}

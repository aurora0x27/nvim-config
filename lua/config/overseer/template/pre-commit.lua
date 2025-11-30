return {
    name = 'run precommit hook',
    condition = function()
        local has_cfg = vim.fn.filereadable(vim.fn.getcwd() .. '/.pre-commit-config.yaml') == 1
            or vim.fn.filereadable(vim.fn.getcwd() .. '/.pre-commit-config.yml') == 1
        local has_binary = vim.fn.executable 'pre-commit'
        if has_binary and has_cfg then
            return true
        elseif not has_binary then
            return false, 'Binary `pre-commit` not found'
        end
        return false
    end,
    builder = function()
        -- This must return an overseer.TaskDefinition
        return {
            -- cmd is the only required field. It can be a list or a string.
            cmd = { 'pre-commit', 'run', '--all-files' },
            -- additional arguments for the cmd (usually only useful if cmd is a string)
            name = 'Run precommit',
            -- set the working directory for the task
            cwd = vim.fn.getcwd(),
        }
    end,
}

local WorkspacePatch = {}

function WorkspacePatch.apply()
    local workspace_nvim = vim.fn.getcwd() .. '/.nvim'
    local secondary = vim.fn.getcwd() .. '/.vscode/nvim'
    if not vim.fn.isdirectory(workspace_nvim) then
        if vim.fn.isdirectory(secondary) == 1 then
            workspace_nvim = secondary
        else
            return
        end
    end

    vim.opt.runtimepath:prepend(workspace_nvim)
    -- Load module
    local init_lua = workspace_nvim .. '/init.lua'
    if vim.fn.filereadable(init_lua) == 1 then
        dofile(init_lua)
    end

    -- Trigger FileType and reload ftplugin
    if vim.bo.filetype ~= '' then
        vim.cmd('doautocmd FileType ' .. vim.bo.filetype)
    end
end

return WorkspacePatch

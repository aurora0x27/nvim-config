-- This file contains options, which is executed after lazy initialization
local options = {}

options.opt = {
    relativenumber = false, -- sets vim.opt.relativenumber
    spell = false, -- sets vim.opt.spell
    signcolumn = 'auto', -- sets vim.opt.signcolumn to auto
    wrap = false, -- sets vim.opt.wrap
    tabstop=4,
    shiftwidth=4,
    expandtab=true,
    smartindent=true,
    autoindent = true,
    cindent=true;
    clipboard = 'unnamedplus',
    termguicolors = true,
    wildmenu = true,
    ignorecase = true,
}

function options.apply()
    for k, v in pairs(options.opt) do
        vim.o[k] = v
    end

    -- vim.opt.wildmenu = true        -- 启用补全菜单
    -- vim.opt.wildignorecase = true  -- 忽略大小写
    -- vim.opt.wildoptions = "pum"    -- 使用弹出菜单（Popup Menu）
    -- vim.opt.wildmode = "longest:full,full" -- 补全模式
end

return options

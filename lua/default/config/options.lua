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
end

return options

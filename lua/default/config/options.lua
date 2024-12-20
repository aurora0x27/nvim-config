local options = {}

options.opt = {
    relativenumber = true, -- sets vim.opt.relativenumber
    number = true, -- sets vim.opt.number
    spell = false, -- sets vim.opt.spell
    signcolumn = 'auto', -- sets vim.opt.signcolumn to auto
    wrap = false, -- sets vim.opt.wrap
    tabstop = 4,
    -- autoindent = true,
    -- cindent=true;
    clipboard = 'unnamedplus',
    termguicolors = true,
}

function options.apply()
    for k, v in pairs(options.opt) do
        vim.o[k] = v
    end
end

return options

local function shorten_cwd(dir)
    local parts = {}
    for p in string.gmatch(dir, '[^/]+') do
        table.insert(parts, p)
    end

    local prefix
    local remaining_parts
    if vim.startswith(dir, '~') then
        prefix = '~'
        remaining_parts = { unpack(parts, 2) }
    else
        prefix = '/' .. parts[1]
        remaining_parts = parts
    end

    if #remaining_parts > 5 then
        local last4 = { unpack(remaining_parts, #remaining_parts - 3, #remaining_parts) }
        return prefix .. '/…' .. '/' .. table.concat(last4, '/')
    else
        return dir
    end
end

local WorkDir = {
    init = function(self)
        local cwd = vim.fn.getcwd(0)
        self.cwd = vim.fn.fnamemodify(cwd, ':~')
        self.mode = vim.fn.mode()
    end,
    provider = function(self)
        return '   ' .. shorten_cwd(self.cwd) .. ' '
    end,
    hl = function(self)
        return { fg = 'black', bg = self.mode_hl[self.mode] or 'replace', bold = true }
    end,
    update = true,
}

return WorkDir

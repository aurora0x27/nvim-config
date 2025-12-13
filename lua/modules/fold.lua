local function fold_virt_text(result, s, lnum, coloff)
    if not coloff then
        coloff = 0
    end
    local text = ''
    local hl
    for i = 1, #s do
        local char = s:sub(i, i)
        local hls = vim.treesitter.get_captures_at_pos(0, lnum, coloff + i - 1)
        local _hl = hls[#hls]
        if _hl then
            local new_hl = '@' .. _hl.capture
            if new_hl ~= hl then
                table.insert(result, { text, hl })
                text = ''
                hl = nil
            end
            text = text .. char
            hl = new_hl
        else
            text = text .. char
        end
    end
    table.insert(result, { text, hl })
end

-- { ... }    󰁂 [xx lines folded]

function _G.custom_foldtext()
    local start = vim.fn.getline(vim.v.foldstart):gsub('\t', string.rep(' ', vim.o.tabstop))
    local end_str = vim.fn.getline(vim.v.foldend)
    local end_ = vim.trim(end_str)
    local start_line = vim.v.foldstart
    local end_line = vim.v.foldend
    local result = {}
    fold_virt_text(result, start, start_line - 1)
    table.insert(result, { ' ... ', 'Delimiter' })
    fold_virt_text(result, end_, end_line - 1, #(end_str:match '^(%s+)' or ''))
    table.insert(result, { '    󰁂 [' .. end_line - start_line .. ' lines folded]', 'CustomFold' })
    return result
end

return {
    apply = function()
        vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        vim.o.foldlevel = 99
        vim.o.foldmethod = 'expr'
        vim.o.foldtext = 'v:lua.custom_foldtext()'
        vim.o.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        vim.o.foldcolumn = '1'
    end,
}

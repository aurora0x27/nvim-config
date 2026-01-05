local tools = require 'utils.tools'

---Move selected block up or down
---@param direction "up"|"down"
return function(direction)
    -- Get the start and the end of visual mode
    local vstart = vim.fn.getpos 'v'
    local vend = vim.fn.getcurpos()

    -- The start and end of visual mode are determined by
    -- the direction of the selection process.
    local start_line = math.min(vstart[2], vend[2])
    local end_line = math.max(vstart[2], vend[2])

    if direction == 'down' then
        if end_line == vim.api.nvim_buf_line_count(0) then
            tools.info('This is the last line of buf', { title = 'Move down' })
            return
        end
        vim.cmd(start_line .. ',' .. end_line .. 'move ' .. end_line .. '+1')
    elseif direction == 'up' then
        if start_line == 1 then
            tools.info('This is the first line of buf', { title = 'Move up' })
            return
        end
        vim.cmd(start_line .. ',' .. end_line .. 'move' .. start_line .. '-2')
    end

    -- \27 refer <Esc> in ASCII code
    vim.api.nvim_feedkeys('\27', '!', true)

    if direction == 'down' then
        vim.api.nvim_feedkeys(start_line + 1 .. 'GV' .. end_line + 1 .. 'G', '!', true)
    elseif direction == 'up' then
        vim.api.nvim_feedkeys(start_line - 1 .. 'GV' .. end_line - 1 .. 'G', '!', true)
    end
end

-- Key configuration for autopair functionality
-- Each key defines whether it's an opening symbol and its paired character
local keys = {
    ['('] = { close = true, pair = '()' },
    ['['] = { close = true, pair = '[]' },
    ['{'] = { close = true, pair = '{}' },

    [')'] = { close = false, pair = '()' },
    [']'] = { close = false, pair = '[]' },
    ['}'] = { close = false, pair = '{}' },

    ['"'] = { close = true, pair = '""' },
    ["'"] = { close = true, pair = "''" },
    ['`'] = { close = true, pair = '``' },

    ['<cr>'] = {},
    ['<bs>'] = {},
}

-- Pre-compute hash table for O(1) pair lookup performance
local pair_lookup = {}
for _, v in pairs(keys) do
    if v.pair then
        pair_lookup[v.pair] = true
    end
end

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

---Get current line and 0-indexed cursor position
---@param mode string 'insert' or 'command' mode
---@return string line The current line content
---@return number col The 0-indexed cursor column position
local function get_info(mode)
    if mode == 'insert' then
        return vim.api.nvim_get_current_line(), vim.api.nvim_win_get_cursor(0)[2]
    else
        return vim.fn.getcmdline(), vim.fn.getcmdpos() - 1
    end
end

---Check if the key is a quote character
---@param key string The key to check
---@return boolean True if the key is a single or double quote
local function is_quote(key)
    return key == '"' or key == "'" or key == '`'
end

--------------------------------------------------------------------------------
-- Handler Functions
--------------------------------------------------------------------------------

---Handle enter key: Insert newline between paired brackets
---@param mode string 'insert' or 'command' mode
---@param is_at_pair boolean Whether the cursor is between a pair
---@return string|nil The key sequence to execute, or nil
local function handle_enter(mode, is_at_pair)
    if mode == 'insert' and is_at_pair then
        return '<cr><c-o>O'
    end
end

---Handle backspace: Delete paired symbols synchronously (including triple quotes)
---@param line string The current line content
---@param col number The 0-indexed cursor column position
---@param is_at_pair boolean Whether the cursor is between a pair
---@return string|nil The key sequence to execute, or nil
local function handle_backspace(line, col, is_at_pair)
    -- Check for triple quotes """|""" or '''|'''
    local trip_double = line:sub(col - 2, col) == '"""' and line:sub(col + 1, col + 3) == '"""'
    local trip_single = line:sub(col - 2, col) == "'''" and line:sub(col + 1, col + 3) == "'''"
    local trip_backtick = line:sub(col - 2, col) == '```' and line:sub(col + 1, col + 3) == '```'

    if trip_double or trip_single or trip_backtick then
        return '<bs><bs><bs><del><del><del>'
    end

    if is_at_pair then
        return '<bs><del>'
    end
end

---Handle Python/Lua triple quotes insertion
---@param key string The quote character being typed
---@param mode string 'insert' or 'command' mode
---@param line string The current line content
---@param col number The 0-indexed cursor column position
---@return string|nil The key sequence to execute, or nil
local function handle_triple_quotes(key, mode, line, col)
    if mode ~= 'insert' or not is_quote(key) then
        return
    end

    local char_before = line:sub(col - 1, col)
    local char_after = line:sub(col + 1, col + 1)

    -- If there are already two identical quotes before and no quote after
    if char_before == key .. key and char_after ~= key then
        return key .. key .. key .. key .. '<Left><Left><Left>'
    end
end

---Handle skipping over closing symbols when they already exist
---@param key string The key being typed
---@param val table {close: boolean, pair: string} The key configuration
---@param line string The current line content
---@param col number The 0-indexed cursor column position
---@return string|nil The key sequence to execute, or nil
local function handle_closing(key, val, line, col)
    -- If it's a closing symbol or a quote
    if not val.close or is_quote(key) then
        local char_after = line:sub(col + 1, col + 1)
        if char_after == key then
            return '<Right>'
        end
    end
end

---Handle opening symbols by inserting the pair
---@param key string The key being typed
---@param val table {close: boolean, pair: string} The key configuration
---@return string The key sequence to execute
local function handle_opening(key, val)
    if val.close then
        return val.pair .. '<Left>'
    end
    return key
end

--------------------------------------------------------------------------------
-- Dispatcher
--------------------------------------------------------------------------------

---Main dispatcher function to handle all autopair operations
---@param key string The key being pressed
---@param val table {close: boolean, pair: string} The key configuration
---@param mode string 'insert' or 'command' mode
---@return string The key sequence to execute
local function update_pairs(key, val, mode)
    local line, col = get_info(mode)
    local pair = line:sub(col, col + 1)
    local is_at_pair = pair_lookup[pair]

    -- Priority-based dispatch
    if key == '<cr>' then
        return handle_enter(mode, is_at_pair) or '<cr>'
    end
    if key == '<bs>' then
        return handle_backspace(line, col, is_at_pair) or '<bs>'
    end

    local triple = handle_triple_quotes(key, mode, line, col)
    if triple then
        return triple
    end

    local skip = handle_closing(key, val, line, col)
    if skip then
        return skip
    end

    return handle_opening(key, val)
end

--------------------------------------------------------------------------------
-- Setup and Application
--------------------------------------------------------------------------------

---Execute autopair setup by creating keymaps for all configured keys
local function exec()
    for key, val in pairs(keys) do
        -- Insert mode
        vim.keymap.set('i', key, function()
            return update_pairs(key, val, 'insert')
        end, { expr = true, replace_keycodes = true })

        -- Command mode
        vim.keymap.set('c', key, function()
            return update_pairs(key, val, 'command')
        end, { expr = true, replace_keycodes = true })
    end
end

---Apply autopair functionality by setting up autocmds
---This delays the keymap setup until first use for better startup performance
local function apply()
    vim.api.nvim_create_autocmd({ 'InsertEnter', 'CmdlineEnter' }, {
        once = true,
        callback = exec,
    })
end

local AutoPairs = { apply = apply }

return AutoPairs

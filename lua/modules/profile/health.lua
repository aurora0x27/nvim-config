local M = {}

local profile = require 'modules.profile'

local pad = require('utils.misc').pad

function M.check()
    vim.health.start 'Profile Loader'

    local info = profile.debug_info()
    local defaults = profile.get_defaults()
    local raw_values = profile.get_raw_tbl()

    if info.path then
        vim.health.info('Config file path: ' .. info.path)
        if vim.uv.fs_stat(info.path) then
            vim.health.ok 'Config file exists and is readable.'
        else
            vim.health.warn 'Config file does not exist (using memory defaults).'
        end
    end

    if #info.masks > 0 then
        vim.health.start 'The following fields are MASKED by environment variables:'
        for _, key in ipairs(info.masks) do
            local env_name = 'NVIM_' .. key:upper()
            vim.health.info(string.format('  - %s (source: %s)', key, env_name))
        end
    else
        vim.health.ok 'No environment variable masks detected.'
    end

    vim.health.info 'Detailed Settings Strategy:'

    local max_key_len = 0
    for k, _ in pairs(defaults) do
        max_key_len = math.max(max_key_len, #k)
    end
    local col_width = max_key_len + 2

    local col_pad = 20

    local header = string.format(
        '  %s | %s | %s | %s',
        pad('Field', col_width),
        pad('Default', col_pad),
        pad('Current', col_pad),
        'Status'
    )
    vim.health.info(header)
    vim.health.info(string.rep('-', #header + 10))

    local keys = vim.tbl_keys(defaults)
    table.sort(keys)

    ---@param s string
    local function get_str(s)
        if #s == 0 then
            return "''"
        elseif #s > col_pad then
            return s:sub(1, col_pad)
        end
        return s
    end

    for _, k in ipairs(keys) do
        local is_masked = vim.tbl_contains(info.masks, k)
        local status = is_masked and '[MASKED]' or (raw_values[k] == defaults[k] and '[DEFAULT]' or '[JSON]')

        local line = string.format(
            '  %s | %s | %s | %s',
            pad(k, col_width),
            pad(get_str(tostring(defaults[k])), col_pad),
            pad(get_str(tostring(raw_values[k])), col_pad),
            status
        )

        vim.health.info(line)
    end

    local logs = profile.get_logs()
    if logs and #logs.data > 0 then
        vim.health.info 'Preload Logs:'
        for _, item in ipairs(logs.data) do
            local msg = string.format('[%s] %s', os.date('%H:%M:%S', item.time / 1000), item.msg)
            if item.lvl >= vim.log.levels.ERROR then
                vim.health.error(msg)
            elseif item.lvl >= vim.log.levels.WARN then
                vim.health.warn(msg)
            else
                vim.health.info(msg)
            end
        end
    end
end

return M

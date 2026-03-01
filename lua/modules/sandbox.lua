local M = {}

local SANDBOX_MODE_DEFAULT = {
    session = false,
    undo = false,
    shada = false,
    swap = false,
    wb = false,
}

local misc = require 'utils.misc'

local Mask = misc.process_feat_mask(require('modules.profile').sandbox_mode, SANDBOX_MODE_DEFAULT, function(msg)
    vim.defer_fn(require('utils.loader').bind(misc.err, msg, { title = 'Sandbox option' }), 100)
end)

function M.get_mask()
    return Mask
end

return M

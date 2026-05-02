--------------------------------------------------------------------------------
-- Cmdline and InputBox
--------------------------------------------------------------------------------
local Win = require 'core.ui.window'
local M = {}

---@class MatchDecl
---@field firstc? string
---@field pattern? string|string[]
---@field prompt? string|string[]

---@class RouteDecl
---@field match MatchDecl
---@field prefix string
---@field hl string
---@field view string
---@field ft? string
---@field title? string

---@class PopupWinOpt
---@field width number
---@field col number
---@field row number
---@field relative 'editor'|'cursor'

---@class PopupOpt
---@field no_register? boolean
---@field cursor_hack? boolean
---@field enable_ui2? boolean
---@field views? table<string, PopupWinOpt>
---@field routes? RouteDecl[]

---@type PopupOpt
local POPUP_OPT_DEFAULT = {
    cursor_hack = false,
    enable_ui2 = false,
    views = {
        cmdline = {
            width = 0.35,
            col = 0.5,
            row = 0.05,
            relative = 'editor',
        },
        input = {
            width = 0.35,
            col = 0.5,
            row = 0.05,
            relative = 'editor',
        },
        lsp_rename = {
            width = 20,
            col = 1,
            row = 1,
            relative = 'cursor',
        },
    },
    routes = {
        {
            match = { firstc = '/' },
            prefix = ' ',
            title = 'Search',
            hl = 'CmdlineSearchDown',
            ft = 'regex',
            view = 'cmdline',
        },
        {
            match = { firstc = '?' },
            prefix = ' ',
            title = 'Search',
            hl = 'CmdlineSearchUp',
            ft = 'regex',
            view = 'cmdline',
        },
        {
            match = { firstc = ':', pattern = '^%s*h[e]?[l]?[p]?%f[%s]' },
            prefix = '?',
            title = 'Help',
            hl = 'CmdlineHelp',
            view = 'cmdline',
        },
        {
            match = { firstc = ':', pattern = '%s*lua%s+' },
            prefix = ' ',
            title = 'Lua',
            hl = 'CmdlineLua',
            ft = 'lua',
            view = 'cmdline',
        },
        {
            match = {
                firstc = ':',
                pattern = {
                    '%s+%!',
                    '^%!',
                },
            },
            prefix = '$',
            title = 'Filter',
            hl = 'CmdlineFilter',
            ft = 'bash',
            view = 'cmdline',
        },
        {
            match = { firstc = '', prompt = 'New Name' },
            prefix = '󰥻 ',
            hl = 'LspRenameInput',
            view = 'lsp_rename',
        },
        {
            match = { firstc = ':' },
            prefix = '',
            hl = 'CmdlineDefault',
            title = 'Cmdline',
            ft = 'vim',
            view = 'cmdline',
        },
        {
            match = { firstc = '' },
            prefix = '󰥻 ',
            hl = 'CmdlineInput',
            view = 'input',
        },
    },
}

local Opt = vim.deepcopy(POPUP_OPT_DEFAULT)

local NeedCursorHack = vim.api.nvim__redraw == nil

local SIDESCROLLOFF = 2

---@type WinOpt
local POPUP_WIN_OPT_DEFAULT = {
    height = 1,
    width = 0.35,
    col = 0.5,
    row = 0.12,
    relative = 'editor',
    border = 'rounded',
    focus_on_open = false,
    focusable = true,
    zindex = 400,
    wo = {
        number = false,
        wrap = false,
        sidescrolloff = SIDESCROLLOFF,
        virtualedit = 'onemore',
        relativenumber = false,
        foldcolumn = '0',
        signcolumn = 'no',
        statuscolumn = ' ',
    },
}

---@class PopupState
---@field win Win
---@field pos number
---@field prompt string
---@field indent number
---@field level number
---@field route RouteDecl
---@field raw_content string
---@field prefix_len integer
---@field origin_pos? {row: number,col: number}

---@type (PopupState|nil)[]
local StatStack = {}

---@type string?
local old_guicursor = nil
local old_ui_cmdline_pos = nil

local function hide_cursor()
    if old_guicursor == nil then
        old_guicursor = vim.go.guicursor
    end
    if old_ui_cmdline_pos == nil then
        old_ui_cmdline_pos = vim.g.ui_cmdline_pos
    end
    -- schedule this, since otherwise Neovide crashes
    vim.schedule(function()
        if old_guicursor then
            vim.go.guicursor = 'a:CmdlineHiddenCursor'
        end
    end)
end

local function show_cursor()
    if old_guicursor then
        if vim.v.exiting == vim.NIL then
            vim.schedule(function()
                if old_guicursor and vim.v.exiting == vim.NIL then
                    -- we need to reset all first and then wait for some time before resetting the guicursor. See #114
                    vim.go.guicursor = 'a:'
                    vim.cmd.redrawstatus()
                    vim.go.guicursor = old_guicursor
                    old_guicursor = nil
                end
            end)
        end
    end
    if old_ui_cmdline_pos then
        vim.g.ui_cmdline_pos = old_ui_cmdline_pos
    end
end

local function last()
    local last_lvl = math.max(1, unpack(vim.tbl_keys(StatStack)))
    return StatStack[last_lvl]
end

function M.on_cmdline_hide(level, _)
    local stat = StatStack[level]
    if stat and stat.win:is_valid() then
        stat.win:close()
    end
    StatStack[level] = nil
    if not last() and NeedCursorHack then
        show_cursor()
    end
end

local ns_id = vim.api.nvim_create_namespace('FakeCmdline')

---@param bufnr integer
---@param prefix string
---@param hl string
---@param pos number (0-indexed)
---@param content string
local function redraw_marks(bufnr, prefix, hl, pos, content)
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

    vim.api.nvim_buf_set_extmark(bufnr, ns_id, 0, 0, {
        virt_text = { { prefix .. ' ', hl } },
        virt_text_pos = 'inline',
        right_gravity = false,
        priority = 100,
    })

    if not NeedCursorHack then
        return
    end

    local char_at_cursor = content:sub(pos + 1, pos + 1)
    if char_at_cursor == '' then
        char_at_cursor = ' '
    end

    vim.api.nvim_buf_set_extmark(bufnr, ns_id, 0, pos, {
        virt_text = { { char_at_cursor, 'Cursor' } },
        virt_text_pos = 'overlay',
        priority = 200,
    })
end

local function redraw_ui(level)
    local stat = StatStack[level]
    if stat and stat.win:is_valid() then
        local win = stat.win
        local win_cfg = vim.api.nvim_win_get_config(win.win)
        vim.g.ui_cmdline_pos = { win_cfg.row + 2, win_cfg.col + 4 }
        redraw_marks(
            win.buf,
            stat.route.prefix,
            stat.route.hl,
            stat.pos,
            stat.raw_content
        )
        if NeedCursorHack then
            pcall(vim.api.nvim_win_set_cursor, win.win, { 1, stat.pos })
            vim.cmd 'redraw!'
        else
            vim.api.nvim_win_call(win.win, function()
                pcall(vim.api.nvim_win_set_cursor, win.win, { 1, stat.pos })
            end)
            pcall(
                vim.api.nvim__redraw,
                { cursor = true, flush = true, win = win.win }
            )
        end
    end
end

function M.on_cmdline_show(content, pos, firstc, prompt, indent, level)
    local raw_content = ''
    for _, chunk in ipairs(content) do
        raw_content = raw_content .. chunk[2]
    end
    local route
    ---@param pat string|string[]
    ---@param str string
    ---@return boolean
    local function try_match_patterns(pat, str)
        if type(pat) == 'string' then
            return str:match(pat) ~= nil
        elseif vim.isarray(pat) then
            for _, p in ipairs(pat) do
                if str:match(p) then
                    return true
                end
            end
        end
        return false
    end
    for _, r in ipairs(Opt.routes) do
        local is_match = true
        local match = r.match
        if match.firstc and match.firstc ~= firstc then
            is_match = false
        end
        if
            match.pattern and not try_match_patterns(match.pattern, raw_content)
        then
            is_match = false
        end
        if match.prompt and not try_match_patterns(match.prompt, prompt) then
            is_match = false
        end
        if is_match then
            route = r
            break
        end
    end

    if not route then
        return
    end

    local view = Opt.views[route.view]
    if not view then
        vim.notify('Cannot find view ' .. route.view, vim.log.levels.ERROR)
        return
    end

    local screen_w = vim.o.columns
    local min_width = Win.resolve_size(view.width, screen_w)
    local prefix_len = #route.prefix + 1

    local content_width =
        math.max(min_width, math.min(#raw_content + prefix_len + SIDESCROLLOFF))

    local stat = StatStack[level]
    local winopt = vim.tbl_deep_extend('force', POPUP_WIN_OPT_DEFAULT, view)
    winopt.ft = route.ft
    winopt.wo = vim.tbl_extend('force', winopt.wo or {}, {
        winhighlight = 'FloatBorder:' .. route.hl .. ',NormalFloat:Normal',
        cursorline = false,
        conceallevel = 2,
    })
    winopt.width = content_width
    local win_title = {
        { ' ' .. (route.title or prompt) .. ' ', route.hl },
    }
    if stat and stat.win:is_valid() then
        -- already open
        stat.win:set_lines { raw_content }
        if stat.origin_pos then
            winopt.col = stat.origin_pos.col
            winopt.row = stat.origin_pos.row
            winopt.relative = 'win'
        end
        stat.win:update(winopt)
        stat.win:set_title(win_title)
        stat.indent = indent
        stat.level = level
        stat.pos = pos
        stat.prompt = prompt
        stat.route = route
        stat.raw_content = raw_content
        stat.prefix_len = prefix_len
    else
        -- new window
        winopt.title = win_title
        local new_win = Win.open(winopt, { raw_content })
        local actual_cfg = vim.api.nvim_win_get_config(new_win.win)
        StatStack[level] = {
            indent = indent,
            level = level,
            pos = pos,
            prompt = prompt,
            win = new_win,
            route = route,
            raw_content = raw_content,
            prefix_len = prefix_len,
            origin_pos = view.relative == 'cursor'
                    and { row = actual_cfg.row, col = actual_cfg.col }
                or nil,
        }
        if NeedCursorHack then
            hide_cursor()
        end
    end
    redraw_ui(level)
end

function M.on_cmdline_pos(pos, level)
    local stat = StatStack[level]
    if not stat then
        return
    end
    stat.pos = pos
    redraw_ui(level)
end

---@param opts PopupOpt|nil
function M.setup(opts)
    Opt = vim.tbl_deep_extend('force', POPUP_OPT_DEFAULT, opts or {})
    NeedCursorHack = NeedCursorHack or Opt.cursor_hack == true

    if Opt.no_register then
        return
    end

    if Opt.enable_ui2 then
        local ui2 = require 'vim._core.ui2'
        ui2.cmd.cmdline_show = M.on_cmdline_show
        ui2.cmd.cmdline_hide = M.on_cmdline_hide
        ui2.cmd.cmdline_pos = M.on_cmdline_pos
    else
        local ns = vim.api.nvim_create_namespace 'PopupUI'
        vim.ui_attach(ns, { ext_cmdline = true }, function(event, ...)
            local callee = M['on_' .. event]
            if type(callee) == 'function' then
                callee(...)
            end
        end)
    end
end

local highlights = {
    CmdlineDefault = { link = 'MiniIconsCyan' },
    CmdlineLua = { link = 'MiniIconsBlue' },
    CmdlineHelp = { link = 'MiniIconsGreen' },
    CmdlineSearchUp = { link = 'MiniIconsOrange' },
    CmdlineSearchDown = { link = 'MiniIconsYellow' },
    CmdlineFilter = { link = 'MiniIconsYellow' },
    CmdlineInput = { link = 'MiniIconsCyan' },
    LspRenameInput = { link = 'MiniIconsPurple' },
    CmdlineHiddenCursor = {
        cterm = { nocombine = true },
        nocombine = true,
        blend = 100,
    },
}
for name, def in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, def)
end

return M

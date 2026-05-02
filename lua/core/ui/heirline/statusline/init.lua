local ViMode = require 'core.ui.heirline.statusline.vimode'
local FileType = require 'core.ui.heirline.statusline.filetype'
local GitStatus = require 'core.ui.heirline.statusline.git-status'
local ScrollBar = require 'core.ui.heirline.statusline.scroll-bar'
local CursorPos = require 'core.ui.heirline.statusline.cursor-pos'
local Diagnostics = require 'core.ui.heirline.statusline.diagnostics'
local LSPInfo = require 'core.ui.heirline.statusline.lsp-info'
local BufName = require 'core.ui.heirline.statusline.bufname'
local WorkDir = require 'core.ui.heirline.statusline.workdir'
local BufInfo = require 'core.ui.heirline.statusline.bufinfo'

local ctrl_v = string.char(22)
local ctrl_s = string.char(19)

--- Status line layout
local StatusLine = {
    static = {
        mode_hl = {
            -- NORMAL family
            n = 'normal',
            no = 'normal',
            nov = 'normal',
            noV = 'normal',
            ['no' .. ctrl_v] = 'normal',
            niI = 'normal',
            niR = 'normal',
            niV = 'normal',
            nt = 'normal',

            -- VISUAL family
            v = 'visual',
            vs = 'visual',
            V = 'visual',
            Vs = 'visual',
            [ctrl_v] = 'visual',
            [ctrl_v .. 's'] = 'visual',

            -- SELECT family
            s = 'select',
            S = 'select',
            [ctrl_s] = 'select',

            -- INSERT family
            i = 'insert',
            ic = 'insert',
            ix = 'insert',

            -- REPLACE family
            R = 'replace',
            Rc = 'replace',
            Rx = 'replace',
            Rv = 'replace',
            Rvc = 'replace',
            Rvx = 'replace',

            -- command family
            c = 'command',
            cv = 'command',
            ce = 'command',

            -- EX mode (still command-like)
            r = 'replace', -- "hit-enter" / replace-like prompt
            rm = 'replace', -- "more"
            ['r?'] = 'replace', -- confirm query
            ['!'] = 'command', -- shell-command mode in cmdline

            -- TERMINAL
            t = 'insert',
        },
    },
    ViMode,
    FileType,
    GitStatus,
    ScrollBar,
    CursorPos,
    { provider = '%=' },
    Diagnostics,
    LSPInfo,
    BufInfo,
    BufName,
    WorkDir,
}

return StatusLine

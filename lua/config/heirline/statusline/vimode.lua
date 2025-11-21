local ViMode = {
    init = function(self)
        self.mode = vim.fn.mode()
    end,
    static = {
        mode_name = {
            n = 'NORMAL',
            no = 'O-PENDING',
            nov = 'O-PENDING',
            noV = 'O-PENDING',
            ['no\22'] = 'O-PENDING',
            niI = 'NORMAL',
            niR = 'NORMAL',
            niV = 'NORMAL',
            nt = 'NORMAL',
            v = 'VISUAL',
            vs = 'VISUAL',
            V = 'V-LINE',
            Vs = 'V-LINE',
            ['\22'] = 'V-BLOCK',
            ['\22s'] = 'V-BLOCK',
            s = 'SELECT',
            S = 'S-LINE',
            ['\19'] = 'S-BLOCK',
            i = 'INSERT',
            ic = 'INSERT',
            ix = 'INSERT',
            R = 'REPLACE',
            Rc = 'REPLACE',
            Rx = 'REPLACE',
            Rv = 'V-REPLACE',
            Rvc = 'V-REPLACE',
            Rvx = 'V-REPLACE',
            c = 'COMMAND',
            cv = 'EX',
            ce = 'EX',
            r = 'REPLACE',
            rm = 'MORE',
            ['r?'] = 'CONFIRM',
            ['!'] = 'SHELL',
            t = 'TERMINAL',
        },
    },
    provider = function(self)
        return ' ' .. (self.mode_name[self.mode] or 'UNKNOWN') .. ' '
    end,
    hl = function(self)
        return { fg = 'black', bg = self.mode_hl[self.mode] or 'red', bold = true }
    end,
    update = {
        'ModeChanged',
        pattern = '*:*',
        callback = vim.schedule_wrap(function()
            vim.cmd 'redrawstatus'
        end),
    },
}

return ViMode

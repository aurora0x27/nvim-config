--[[
###############################################
#        ██████╗ ███████╗███████╗██╗          #
#       ██╔═══██╗██╔════╝╚══███╔╝██║          #
#       ██║   ██║█████╗    ███╔╝ ██║          #
#       ██║▄▄ ██║██╔══╝   ███╔╝  ██║          #
#       ╚██████╔╝██║     ███████╗███████╗     #
#        ╚══▀▀═╝ ╚═╝     ╚══════╝╚══════╝     #
###############################################
--]]

-- DEBUG MODE
local debug_mode = vim.env.NVIM_CONFIG_DEV

local function set_rtpath()
    vim.opt.rtp:prepend(vim.env.SCRIPT_DIR)
end

if debug_mode == '1' then
    local project_root = vim.env.SCRIPT_DIR
    ---@diagnostic disable: duplicate-set-field
    vim.fn.stdpath = function(what)
        if what == 'config' then
            return project_root
        else
            return vim.fn.call('stdpath', { what })
        end
    end
    set_rtpath()
end
-- DEBUG MODE

-- Load user defined settings after Lazy initialization
vim.api.nvim_create_autocmd('User', {
    pattern = 'LazyVimStarted',
    callback = function()
        vim.schedule(function()
            -- DEBUG MODE
            if debug_mode == '1' then
                set_rtpath()
            end
            -- DEBUG MODE

            require('config.keymaps').apply()
            require('config.options').apply()
            require('config.autocmd').apply()
            require('config.diagnostics').apply()
            require('config.lsp').apply()
        end)
    end,
})

-- set global leader
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('config.preload').apply()

-- set lazy path
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
---@diagnostic disable: undefined-field
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
    local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
    if vim.v.shell_error ~= 0 then
        error('Error cloning lazy.nvim:\n' .. out)
    end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- import plugins
require('lazy').setup {
    -- all the plugins' configure files should be put under `lua/plugins`
    spec = {
        { import = 'plugins' },
    },
    -- }, --[[@as LazySpec]] {
    -- Configure any other `lazy.nvim` configuration options here

    install = {
        colorscheme = { 'catppuccin' },
    },
    ui = {
        backdrop = 100,
        border = 'rounded',
    },
    performance = {
        rtp = {
            -- disable some rtp plugins, add more to your liking
            disabled_plugins = {},
        },
    },
    config = function()
        -- apply options and keymaps
        -- must be put here as hook because plugin loading is async
    end,
    ---@diagnostic disable: undefined-doc-name
} --[[@as LazyConfig]]

--[[

                        .:...:=.
                    :=----:-=*+--
                    =---:--:+*#++-
                   :-:=--::.-*++=-:
                  .+--.------##*---.
                  =+===:..===*#:-:::.
                 .=+-=+:.  :*+. :::::
                 :-*--+-:.:---. .:::::
                .:-==...:=---=.  -:::::
                :::--..+**--:  . ::::::.
               .::::-.:++=+=...: .-:::::.
               ::--:-::-=::--..:  --:::::.
              ..-=-=+=:+---+==--  .=-:::::
              ::+++*+:=*+=-+***=   +=-:::..
             ..-++*+.:+-+=-:+#*=   -+=:::. .
            . .++*+:.++:--. =##+   .++:... ..
            ..+****=-**-=+. =##*    =+=.... .
           ..=*====-+=**:== =##*.   :++::... .
          .::=:==---*-=-===-+#**-   .=+-:::....
          ::+=:++=++=+-:=*+-*#+=*    -*+:::::...
         ::-*++###%%+-=--+-+*%+=#.   :++::::::::
        .--##+#*#%%%#-::-*###%*=*=   .=+-::::::::
        -:*#*#-+#*##*#=*#**=#%*=+*    -*-:::::::-
       :::+*#*====****+**--.%%*++*:   :+-:::::::::
      .-:=+==-::::=-:-====:-%#*+=#+   .=-:::::::::
     .-:-**+++=-:.::  ..:-=*=***++:   .=-::::::::-
    .:::+***+##*#*=.   =#***-..:..    .--:::::::::
    :::-*#***##***-    .#***+         .-::--::::::.
   .:::=*#***##**+:     =#**#.        ::-=---:::::.
   :::-=*****##*#+:     .####-        ::=+==-::::::
  .:::-==+***####=:      *###+        --**+=--::::.
  .::::-==+**####+-      -####       :-=**+=--::..
  ..:::--=***##*#*=       #***:      --+*++=--:. .
  ...::--=***%**#=+.      =**#-     :==+++===-:..
  :::-:--=*+*%##+:.:       *###.    =++++=====--.
  :::----=++#%##:  :.      :###*   :**+*++++++-:
  ::-----=++%%%+    .       -%#%+  -+*******+--
   --++===**%##:             -%%%: :-=+++***-:
   .-++*****%##               =##*  :.+++++-.
     =**+++:%#+                *##-  ..=-=.
      .==--:%#-                :%#*    ::
        .:::%#-                 +#*.   .
           .##=                 .#*+
           .#+*.                :**+:
           .#++-                ++=*-
            #*+*:              -*++#:
            :+--.              .-=--

--]]

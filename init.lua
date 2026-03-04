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

if vim.loader then
    vim.loader.enable()
end

-- DEBUG MODE
vim.g.debug_mode = vim.env.NVIM_CONFIG_DEV

local function set_rtpath()
    vim.opt.rtp:prepend(vim.env.SCRIPT_DIR)
end

if vim.g.debug_mode == '1' then
    local project_root = vim.env.SCRIPT_DIR
    ---@diagnostic disable: inject-field, duplicate-set-field
    vim.fn.stdpath = function(what)
        if what == 'config' then
            return project_root
        else
            return vim.fn.call('stdpath', { what })
        end
    end
    set_rtpath()
    vim.api.nvim_create_autocmd('VimEnter', {
        once = true,
        callback = function()
            vim.defer_fn(function()
                vim.notify('Entered DEBUG mode', vim.log.levels.WARN, { title = 'Config' })
            end, 150)
        end,
    })
end
-- DEBUG MODE

-- Load user defined settings after Lazy initialization
vim.api.nvim_create_autocmd('User', {
    pattern = 'LazyVimStarted',
    callback = function()
        vim.schedule(function()
            local profile = require 'modules.profile'

            if profile.enable_lsp then
                require('modules.lsp').setup()
            end
            if not profile.disable_im_switch then
                require('modules.im-switch').setup()
            end
            require('modules.keymaps').setup()
            require('modules.options').setup()
            require('modules.autocmd').setup()
            require('modules.diagnostics').setup()
            require('modules.fold').setup()
            require('modules.ssh_mode').setup()
            require('modules.pairs').setup()
            require('modules.patch').setup()

            -- emit diagnostics info of profile module after noice initialized
            if not profile.silent_profile_diag then
                vim.defer_fn(require('modules.profile').emit_err, 100)
            end

            -- emit diagnostics info of lang module after noice initialized
            if not profile.silent_lang_diag then
                vim.defer_fn(require('modules.lang').emit_err, 100)
            end
        end)
    end,
})

require('modules.preload').setup()

-- set lazy path
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
---@diagnostic disable: undefined-field
if not vim.uv.fs_stat(lazypath) then
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
        { import = 'plugins.core' },
        require('modules.profile')
            .create_lazy_spec_mask_builder()
            :pipe(require('modules.lang').mask_lazy_spec)
            .unpack(),
    },
    install = {
        colorscheme = { 'default' },
    },
    ui = {
        backdrop = 100,
        width = 0.8,
        height = 0.8,
        border = 'rounded',
    },
    performance = {
        rtp = {
            -- disable some rtp plugins, add more to your liking
            disabled_plugins = {
                'gzip',
                'tarPlugin',
                'zipPlugin',
                'netrwPlugin',
                'tohtml',
                'tutor',
            },
        },
    },
} --[[@as LazyConfig]]

--[[
-- NOTE:
   #############################################################################################
   #               ██╗  ██╗ █████╗ ████████╗███████╗██╗   ██╗███╗   ██╗███████╗                #
   #               ██║  ██║██╔══██╗╚══██╔══╝██╔════╝██║   ██║████╗  ██║██╔════╝                #
   #               ███████║███████║   ██║   ███████╗██║   ██║██╔██╗ ██║█████╗                  #
   #               ██╔══██║██╔══██║   ██║   ╚════██║██║   ██║██║╚██╗██║██╔══╝                  #
   #               ██║  ██║██║  ██║   ██║   ███████║╚██████╔╝██║ ╚████║███████╗                #
   #               ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝                #
   #                                                                                           #
   #                           ███╗   ███╗██╗██╗  ██╗██╗   ██╗                                 #
   #                           ████╗ ████║██║██║ ██╔╝██║   ██║                                 #
   #                           ██╔████╔██║██║█████╔╝ ██║   ██║                                 #
   #                           ██║╚██╔╝██║██║██╔═██╗ ██║   ██║                                 #
   #                           ██║ ╚═╝ ██║██║██║  ██╗╚██████╔╝                                 #
   #                           ╚═╝     ╚═╝╚═╝╚═╝  ╚═╝ ╚═════╝                                  #
   #############################################################################################


-- NOTE:
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

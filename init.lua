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

if vim.g.vscode then
    vim.notify(
        'Cannot apply this configuration to vscode, Nothing is loaded',
        vim.log.levels.WARN
    )
    return
end

-- Enable aot bytecode
if vim.loader then
    vim.loader.enable()
end

--------------------------------------------------------------------------------
-- Phase 0: DEBUG MODE
--------------------------------------------------------------------------------
vim.g.debug_mode = vim.env.NVIM_CONFIG_DEV
if vim.g.debug_mode == '1' then
    local project_root = vim.env.NVIM_CONFIG_DEV_CONFIG_ROOT
    local cache_root = vim.env.NVIM_CONFIG_DEV_CACHE_ROOT

    if not project_root then
        vim.notify(
            'DEBUG mode is set but config root is missing',
            vim.log.levels.ERROR,
            { title = 'Config Hack' }
        )
        return
    end
    if not cache_root then
        vim.notify(
            'DEBUG mode is set but cache root is missing',
            vim.log.levels.WARN,
            { title = 'Config Hack' }
        )
        return
    end

    local function set_rtpath()
        vim.opt.rtp:prepend(project_root)
    end

    local shadow = {
        config = project_root,
        cache = cache_root .. '/cache',
        data = cache_root .. '/share',
        state = cache_root .. '/state',
        log = cache_root .. '/state/log',
        run = cache_root .. '/run',
        config_dirs = { project_root },
        data_dirs = { cache_root .. '/share' },
    }

    --- Hack vim.stdpath, create a sandbox
    ---@diagnostic disable: inject-field, duplicate-set-field
    vim.fn.stdpath = function(what)
        return shadow[what] --or vim.fn.call('stdpath', { what })
    end

    set_rtpath()

    --- Hint
    vim.api.nvim_create_autocmd('VimEnter', {
        once = true,
        callback = function()
            vim.defer_fn(function()
                vim.notify(
                    'Entered DEBUG mode',
                    vim.log.levels.WARN,
                    { title = 'Config' }
                )
            end, 150)
        end,
    })
end
--------------------------------------------------------------------------------
-- END DEBUG MODE
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Phase 3: Load user defined settings after Lazy initialization
--------------------------------------------------------------------------------
vim.api.nvim_create_autocmd('User', {
    pattern = 'LazyVimStarted',
    once = true,
    callback = vim.schedule_wrap(function()
        if not Profile.disable_im_switch then
            require 'edit.im-switch'.setup()
        end
        require 'edit.keymaps'.setup()
        require 'edit.options'.setup()
        require 'edit.autocmd'.setup()
        require 'edit.diagnostics'.setup()
        require 'edit.fold'.setup()
        require 'edit.ssh-mode'.setup()
        require 'edit.pairs'.setup()

        -- dofile init.lua
        require 'core.workspace'.load_main()
    end),
})

--------------------------------------------------------------------------------
-- Phase 1: Initialize UI event adapter, load preload module and detect
--          workspace patch
--------------------------------------------------------------------------------
require 'core.adapter'.setup {
    bus_init = { bus_backend = 'toast' },
    popup = {
        cursor_hack = false,
        no_register = true,
    },
}

local PatchDir, Nvimrc = require 'core.workspace'.probe()

require 'core.profile'.setup {
    files_to_merge = Nvimrc and { Nvimrc } or {},
}

require 'core.lang'.setup {
    blacklist = Profile.lang_blacklist,
    whitelist = Profile.lang_whitelist,
    levels = Profile.lang_levels,
}

require 'core.preload'.setup()
require 'core.workspace'.setup()

vim.api.nvim_create_autocmd('UIEnter', {
    once = true,
    callback = require 'utils.loader'.thunk('core.bus.backend.toast', 'setup'),
})

--------------------------------------------------------------------------------
-- Phase 2: Bootstrap and load lazy
--------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
---@diagnostic disable: undefined-field
if not vim.uv.fs_stat(lazypath) then
    local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
    local out = vim.fn.system {
        'git',
        'clone',
        '--filter=blob:none',
        '--branch=stable',
        lazyrepo,
        lazypath,
    }
    if vim.v.shell_error ~= 0 then
        error('Error cloning lazy.nvim:\n' .. out)
    end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

local Icons = {
    Kind = require 'assets.icons'.get('kind'),
    Documents = require 'assets.icons'.get('documents'),
    UI = require 'assets.icons'.get('ui'),
    UISep = require 'assets.icons'.get('ui', true),
    Misc = require 'assets.icons'.get('misc'),
}

-- import plugins
require('lazy').setup {
    -- all the plugins' configure files should be put under `lua/plugins`
    spec = {
        { import = 'plugins.core' },
        Profile.create_lazy_spec_mask_builder()
            :pipe(Lang.mask_lazy_spec)
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
        icons = {
            cmd = Icons.Misc.Code,
            config = Icons.UI.Gear,
            event = Icons.Kind.Event,
            ft = Icons.Documents.Files,
            init = Icons.Misc.Gear,
            import = Icons.Documents.Import,
            keys = Icons.UI.Keyboard,
            loaded = Icons.UI.Check,
            not_loaded = Icons.UI.Circle,
            plugin = Icons.UI.Package,
            runtime = Icons.Misc.Vim,
            source = Icons.Kind.StaticMethod,
            start = Icons.UI.Play,
            list = {
                Icons.UISep.Dot,
                Icons.UISep.Circle,
                Icons.UISep.Right,
                Icons.UISep.ArrowRight,
            },
        },
    },
    performance = {
        rtp = {
            reset = true,
            -- keep workspace patch dir in rtp
            paths = { PatchDir },
            -- disable some rtp plugins, add more to your liking
            disabled_plugins = {
                'gzip',
                'matchit',
                'matchparen',
                'netrwPlugin',
                'tarPlugin',
                'tohtml',
                'tutor',
                'zipPlugin',
            },
        },
    },
} --[[@as LazyConfig]]

--[[
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

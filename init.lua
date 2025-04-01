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

-- TODO: set an sepearate environment while debugging
function set_rtpath()
    -- local test_path = vim.fn.fnamemodify("./nvim-cache", ":p") -- 轉換為絕對路徑
    vim.opt.rtp:prepend("/home/aurora/Desktop/projects/debug/nvim-config")
    -- vim.opt.rtp:prepend(test_path)
    -- vim.opt.rtp:prepend(vim.fn.fnamemodify(".", ":p")) -- 把當前目錄也加進去
end
-- TODO: end env settings

-- FIXME: Move this when using it
set_rtpath()
-- END FIXME

-- Load user defined settings after Lazy initialization
vim.api.nvim_create_autocmd("User", {
    pattern = "LazyVimStarted",
    callback = function()
        vim.schedule(function()
            set_rtpath()
            require('default.config.keymaps').apply()
            require('default.config.options').apply()
            require('default.config.autocmd').apply()
        end)
    end,
})

-- require('default.config.keymaps').apply()
-- require('default.config.options').apply()

-- set global leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require('default.config.preload').apply()

-- set lazy path
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
    local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
    if vim.v.shell_error ~= 0 then
        error('Error cloning lazy.nvim:\n' .. out)
    end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- import plugins
require('lazy').setup({
    -- all the plugins' configure files should be put under `lua/plugins`
    spec = {
        { import = "default.plugins" }, -- 這會自動加載所有 lua/default/plugins/*.lua 文件
        -- 其他全局插件...
    },
} --[[@as LazySpec]], {
    -- Configure any other `lazy.nvim` configuration options here
    install = { colorscheme = { 'catppuccin' } },
    ui = { backdrop = 100 },
    performance = {
        rtp = {
            -- disable some rtp plugins, add more to your liking
            disabled_plugins = {},
        },
    },
    config = function()
        -- apply options and keymaps
        -- must be put here as hook because plugin loading is async
        -- require('default.config.autocmd')
    end,
} --[[@as LazyConfig]])

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

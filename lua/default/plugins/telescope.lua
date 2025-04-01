return {
    'nvim-telescope/telescope.nvim',
    opts = {
        defaults = {
            layout_config = {
                prompt_position = "top"
            },
            sorting_strategy = "ascending", -- 讓結果從上往下排序
            file_ignore_patterns = {
                'logs',
                '%.md',
                '%.root',
                '%.gif',
                '%.pdf',
                '%.png',
                '%.vcxproj',
                '%.vcproj',
                '%.notes',
                '%.json',
                '%.rst',
                '%.bat',
                '%.css',
                '%.cxx',
                '%.cmake',
                'Online.*%.xml',
            },
        },
    },
}

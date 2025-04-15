return {
    'nvim-telescope/telescope.nvim',
    opts = {
        defaults = {
            layout_config = {
                prompt_position = "top"
            },
            sorting_strategy = "ascending",
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

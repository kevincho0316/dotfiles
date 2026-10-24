return {
    {
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
        ft = { "markdown" },
        opts = {},
    },
    {
        "iamcco/markdown-preview.nvim",
        build = "cd app && npm install",
        init = function()
            vim.g.mkdp_filetypes = { "markdown" }
        end,
        config = function()
            vim.keymap.set("n", "<Leader>mp", "<Plug>MarkdownPreview", { desc = "Markdown Preview" })
        end,
    },

    {
        "bullets-vim/bullets.vim",
        ft = { "markdown", "text" },
    },
    {
        "dhruvasagar/vim-table-mode",
        ft = { "markdown" },
    },
}

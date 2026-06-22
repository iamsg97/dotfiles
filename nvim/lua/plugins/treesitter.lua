return {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    opts = {
        ensure_installed = {
            "python", "rust", "go", "java",
            "javascript", "typescript", "tsx",
            "lua", "fish", "bash",
            "json", "yaml", "toml", "markdown", "markdown_inline",
            "gitignore", "diff",
        },
        highlight = { enable = true },
        indent = { enable = true },
    },
    config = function(_, opts)
        require("nvim-treesitter.configs").setup(opts)
    end,
}

-- nvim-treesitter `main` branch: the rewrite for Neovim 0.11+.
-- The legacy `master` branch's query directives read `match[id]` as a single node
-- (pre-0.11 format); Neovim 0.12 passes a list there, which corrupts injection ranges
-- and crashes the highlighter (e.g. on markdown fenced code blocks). `main` uses the
-- new API and a different setup: install parsers, then enable highlighting via
-- `vim.treesitter.start()` per buffer instead of a `configs.setup({ highlight = ... })`.
return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter").install({
            "python", "rust", "go", "java",
            "javascript", "typescript", "tsx",
            "lua", "fish", "bash",
            "json", "yaml", "toml", "markdown", "markdown_inline",
            "gitignore", "diff",
        })

        -- Enable treesitter highlighting + indentation for any buffer whose filetype
        -- has an installed parser. The pcall keeps buffers without a parser quiet.
        vim.api.nvim_create_autocmd("FileType", {
            callback = function(ev)
                if pcall(vim.treesitter.start, ev.buf) then
                    vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end
            end,
        })
    end,
}

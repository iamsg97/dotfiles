return {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = {
        format_on_save = { timeout_ms = 1000, lsp_fallback = true },
        formatters_by_ft = {
            lua = { "stylua" },
            python = { "ruff_format" },
            go = { "gofumpt", "goimports" },
            javascript = { "prettier" },
            typescript = { "prettier" },
            typescriptreact = { "prettier" },
            json = { "prettier" },
            yaml = { "prettier" },
            markdown = { "prettier" },
            fish = { "fish_indent" },
        },
    },
}

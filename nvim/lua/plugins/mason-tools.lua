-- Non-LSP CLI tools that conform.lua and the LSPs shell out to.
return {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
        ensure_installed = { "stylua", "gofumpt", "goimports", "prettier" },
    },
}

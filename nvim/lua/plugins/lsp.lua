-- rust-analyzer, gopls, and ruff are NOT managed by mason here — they're already
-- on PATH via `rustup component add rust-analyzer`, `go install golang.org/x/tools/gopls`,
-- and `uv tool install ruff` (see dependencies.sh), so lspconfig just points at the
-- system binaries. Mason's ruff installer shells out to the system python3's pip,
-- which isn't guaranteed to have the pip module installed.
return {
    {
        "mason-org/mason.nvim",
        opts = {},
    },
    {
        "mason-org/mason-lspconfig.nvim",
        dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
        opts = {
            ensure_installed = {
                "lua_ls",
                "pyright",
                "ts_ls",
                "jdtls",
                "bashls",
                "jsonls",
                "yamlls",
            },
        },
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = { "saghen/blink.cmp" },
        config = function()
            local capabilities = require("blink.cmp").get_lsp_capabilities()

            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(args)
                    local bufnr = args.buf
                    local opts = { buffer = bufnr }
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Goto definition" }))
                    vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "Goto references" }))
                    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Goto implementation" }))
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover" }))
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
                    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
                    vim.keymap.set("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, vim.tbl_extend("force", opts, { desc = "Format buffer" }))
                end,
            })

            vim.lsp.config("*", { capabilities = capabilities })

            local servers =
                { "lua_ls", "pyright", "ruff", "ts_ls", "jdtls", "bashls", "jsonls", "yamlls", "rust_analyzer", "gopls" }
            vim.lsp.enable(servers)
        end,
    },
}

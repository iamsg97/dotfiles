-- Neogit: a Magit-style Git UI for Neovim. diffview.nvim provides the diffs and
-- the 3-way view used to resolve merge conflicts; fzf-lua backs Neogit's pickers.
-- gitsigns stays responsible for inline hunk signs/staging (<leader>h*).
return {
    "NeogitOrg/neogit",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "sindrets/diffview.nvim",
        "ibhagwan/fzf-lua",
    },
    opts = {
        integrations = {
            diffview = true,
            fzf_lua = true,
        },
    },
    keys = {
        { "<leader>gg", "<cmd>Neogit<CR>", desc = "Neogit status" },
        { "<leader>gc", "<cmd>Neogit commit<CR>", desc = "Git commit" },
        { "<leader>gl", "<cmd>Neogit log<CR>", desc = "Git log" },
        { "<leader>gp", "<cmd>Neogit pull<CR>", desc = "Git pull" },
        { "<leader>gP", "<cmd>Neogit push<CR>", desc = "Git push" },
        -- diffview: working-tree diff, file history, and merge-conflict resolution
        { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Diff view (working tree)" },
        { "<leader>gm", "<cmd>DiffviewOpen<CR>", desc = "Resolve merge conflicts" },
        { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "File history (current file)" },
        { "<leader>gx", "<cmd>DiffviewClose<CR>", desc = "Close diff view" },
    },
}

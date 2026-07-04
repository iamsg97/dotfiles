-- diffview.nvim: side-by-side diffs, file history, and the 3-way view used
-- to resolve merge conflicts. gitsigns stays responsible for inline hunk
-- signs/staging (<leader>h*); lazygit.lua covers the interactive Git TUI.
return {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Diff view (working tree)" },
        { "<leader>gm", "<cmd>DiffviewOpen<CR>", desc = "Resolve merge conflicts" },
        { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "File history (current file)" },
        { "<leader>gx", "<cmd>DiffviewClose<CR>", desc = "Close diff view" },
    },
}

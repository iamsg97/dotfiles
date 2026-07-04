-- LazyGit: full Git TUI (status, stage, commit, branch, push/pull, log) in a
-- floating terminal, using the same `lazygit` binary as the shell's `lg` alias.
return {
    "kdheepak/lazygit.nvim",
    cmd = {
        "LazyGit",
        "LazyGitConfig",
        "LazyGitCurrentFile",
        "LazyGitFilter",
        "LazyGitFilterCurrentFile",
    },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        { "<leader>gg", "<cmd>LazyGit<CR>", desc = "LazyGit" },
    },
}

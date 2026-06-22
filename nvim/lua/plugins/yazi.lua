-- File manager integration, using the same yazi binary as the shell's `y` function
-- and zellij's Alt+y floating pane.
return {
    "mikavilpas/yazi.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        { "<leader>-", "<cmd>Yazi<CR>", desc = "Open yazi at current file" },
        { "<leader>cw", "<cmd>Yazi cwd<CR>", desc = "Open yazi in working directory" },
    },
    opts = {
        open_for_directories = true,
    },
}

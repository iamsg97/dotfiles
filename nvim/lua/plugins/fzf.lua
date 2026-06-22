-- Uses the fzf binary already installed via dependencies.sh.
return {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
    keys = {
        { "<leader>ff", "<cmd>FzfLua files<CR>", desc = "Find files" },
        { "<leader>fg", "<cmd>FzfLua live_grep<CR>", desc = "Live grep" },
        { "<leader>fb", "<cmd>FzfLua buffers<CR>", desc = "Find buffers" },
        { "<leader>fh", "<cmd>FzfLua help_tags<CR>", desc = "Help tags" },
        { "<leader>fo", "<cmd>FzfLua oldfiles<CR>", desc = "Recent files" },
        { "<leader>fr", "<cmd>FzfLua resume<CR>", desc = "Resume last search" },
    },
}

-- sainnhe/edge for a soft, low-contrast palette across the editor.
return {
    "sainnhe/edge",
    lazy = false,
    priority = 1000,
    config = function()
        -- These globals must be set before the colorscheme command.
        vim.g.edge_style = "default" -- default | aura | neon
        vim.g.edge_better_performance = 1 -- ship a precompiled palette for faster startup
        vim.g.edge_enable_italic = 1
        vim.g.edge_dim_inactive_windows = 1
        vim.g.edge_diagnostic_text_highlight = 1
        vim.cmd.colorscheme("edge")
    end,
}

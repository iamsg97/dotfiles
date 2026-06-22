-- Srcery to match the zellij theme for a consistent terminal+editor palette.
return {
    "srcery-colors/srcery-vim",
    lazy = false,
    priority = 1000,
    config = function()
        vim.cmd.colorscheme("srcery")
    end,
}

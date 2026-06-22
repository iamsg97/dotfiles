local opt = vim.opt

vim.g.mapleader = " "
vim.g.maplocalleader = " "

opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.wrap = false

opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true

opt.splitright = true
opt.splitbelow = true

opt.termguicolors = true
opt.updatetime = 250
opt.timeoutlen = 400

opt.undofile = true
opt.swapfile = false
opt.clipboard = "unnamedplus"

opt.mouse = "a"
opt.completeopt = { "menu", "menuone", "noselect" }

local opt = vim.opt

opt.timeoutlen = 300

vim.wo.fillchars = "eob: "
opt.fillchars = opt.fillchars + "diff:╱"
vim.scriptencoding = "utf-8"
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"
vim.g.termguicolors = true

opt.number = true
vim.wo.number = true

opt.title = true
opt.hlsearch = true
opt.backup = false
opt.showcmd = true
opt.cmdheight = 1
opt.expandtab = true

opt.so = 30
opt.shell = "zsh"

opt.shiftwidth = 2
opt.tabstop = 2
opt.wrap = false

opt.cul = true -- cursor line
opt.mouse = "a"
opt.pumheight = 10
opt.numberwidth = 2
opt.ruler = false

opt.signcolumn = "yes"
opt.clipboard = "unnamedplus"

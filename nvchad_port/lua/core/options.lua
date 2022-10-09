local opt = vim.opt
local g = vim.g

g.mapleader = " "
g.maplocalleader = " "

opt.expandtab = true
opt.shiftwidth = 2
opt.smartindent = true
opt.tabstop = 2
opt.softtabstop = 2
opt.wrap = false

opt.title = true
opt.clipboard = "unnamedplus"
opt.cul = true -- cursor line

opt.fillchars = opt.fillchars + "diff:╱"
opt.ignorecase = true
opt.smartcase = true
opt.mouse = "a"

opt.pumheight = 10 -- popup window max-height strokes
-- Numbers
opt.number = true
opt.numberwidth = 2
opt.ruler = false

-- disable nvim intro
opt.shortmess:append("sI")

opt.signcolumn = "yes"
opt.splitbelow = true
opt.splitright = true
opt.termguicolors = true
opt.timeoutlen = 400
opt.undofile = true

-- interval for writing swap file to disk, also used by gitsigns
opt.updatetime = 250

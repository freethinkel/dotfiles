local opt = vim.opt

opt.nu = true
opt.numberwidth = 2
opt.ruler = false
opt.relativenumber = true

opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.expandtab = true
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true
opt.mouse = "a"

opt.so = 80
opt.colorcolumn = "80"
opt.cursorline = true

opt.fillchars = { eob = " " }
opt.fillchars = opt.fillchars + "eob: " + "diff:╱"
opt.wrap = false
opt.swapfile = false
opt.backup = false
opt.signcolumn = "yes"

opt.incsearch = true

opt.updatetime = 50
-- opt.clipboard = "unnamedplus"
opt.clipboard:append("unnamedplus")

vim.cmd("au BufNewFile,BufRead *.pcss set ft=postcss")
vim.cmd("au BufNewFile,BufRead *.mdx set ft=mdx")

local custom_colors = require("custom.colors")

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.timeoutlen = 300
vim.opt.swapfile = false
vim.opt.so = 20
vim.opt.fillchars = vim.opt.fillchars + "diff:╱"

vim.cmd("au BufNewFile,BufRead *.pcss set ft=postcss")
vim.cmd("au BufNewFile,BufRead *.mdx set ft=mdx")
vim.cmd("hi DiffviewDiffAddAsDelete guifg=NONE guibg=" .. custom_colors.diff_delete)

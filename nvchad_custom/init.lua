-- local autocmd = vim.api.nvim_create_autocmd

-- Auto resize panes when resizing nvim window
-- autocmd("VimResized", {
--   pattern = "*",
--   command = "tabdo wincmd =",

vim.cmd("au BufNewFile,BufRead *.pcss set ft=postcss")
vim.cmd("au BufNewFile,BufRead *.mdx set ft=markdown")

local opt = vim.opt

opt.fillchars = { eob = " " }
opt.fillchars = opt.fillchars + "diff:╱"

opt.so = 10
opt.pumheight = 10
opt.relativenumber = true
opt.wrap = false
opt.cursorline = true
opt.swapfile = false

local custom_colors = require("custom.colors")

vim.opt.signcolumn = "yes"
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.timeoutlen = 300
vim.opt.swapfile = false
vim.opt.so = 20
vim.opt.fillchars = vim.opt.fillchars + "diff:╱"

vim.cmd("au BufNewFile,BufRead *.pcss set ft=postcss")
vim.cmd("au BufNewFile,BufRead *.mdx set ft=mdx")
vim.cmd("hi DiffviewDiffAddAsDelete guifg=NONE guibg=" .. custom_colors.diff_delete)

vim.cmd("highlight DiagnosticUnderlineError cterm=undercurl gui=undercurl guisp=" .. custom_colors.error_unerline)
vim.cmd("highlight DiagnosticUnderlineWarn cterm=undercurl gui=undercurl guisp=" .. custom_colors.warn_unerline)
vim.cmd("highlight DiagnosticUnderlineInfo cterm=undercurl gui=undercurl")
vim.cmd("highlight DiagnosticUnderlineHint cterm=undercurl gui=undercurl")

local neovide_setup = function()
	vim.g.neovide_floating_blur_amount_x = 9.0
	vim.g.neovide_floating_blur_amount_y = 9.0
end

if vim.g.neovide then
	neovide_setup()
end

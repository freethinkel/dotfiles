vim.opt.fillchars = vim.opt.fillchars + "diff:╱"
vim.cmd("au BufNewFile,BufRead *.pcss set ft=postcss")

vim.opt.wrap = false

vim.api.nvim_create_autocmd({ "ColorScheme" }, {
	pattern = "*",
	callback = function()
		require("custom.highlights").override_hightlight()
	end,
})

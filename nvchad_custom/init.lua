vim.opt.fillchars = vim.opt.fillchars + "diff:╱" + "eob: "

-- OTHER
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])
-- WEZTERM
-- vim.cmd([[let &t_Cs = "\e[60m"]])
-- vim.cmd([[let &t_Ce = "\e[24m"]])

vim.cmd("au BufNewFile,BufRead *.pcss set ft=css")
vim.cmd("au BufNewFile,BufRead *.mdx set ft=markdown")

vim.opt.swapfile = false
vim.opt.wrap = false
vim.opt.relativenumber = true
-- vim.opt.so = 8
-- vim.opt.diffopt = "internal,filler,closeoff,iwhite"

vim.api.nvim_create_autocmd({ "ColorScheme" }, {
	pattern = "*",
	callback = function()
		require("custom.highlights").override_highlights()
	end,
})

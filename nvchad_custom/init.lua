vim.opt.fillchars = vim.opt.fillchars + "diff:╱"
vim.cmd("au BufNewFile,BufRead *.pcss set ft=postcss")

vim.opt.wrap = false
vim.opt.so = 20

vim.api.nvim_create_autocmd({ "ColorScheme" }, {
	pattern = "*",
	callback = function()
		require("custom.highlights").override_hightlight()
	end,
})

if vim.g.neovide then
	vim.o.guifont = "Iosevka Nerd Font:h14"
	vim.g.neovide_transparency = 0.8

	vim.g.transparency = 0.8
	-- vim.g.neovide_background_color = "#0f1117" .. alpha()
	vim.g.neovide_floating_blur_amount_x = 10.0
	vim.g.neovide_floating_blur_amount_y = 10.0
	vim.g.neovide_scroll_animation_length = 0.3
end

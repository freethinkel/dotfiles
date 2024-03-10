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

if vim.g.neovide then
	-- vim.o.guifont = "FiraCode Nerd Font:h14"
	-- vim.opt.linespace = 1
	vim.opt.linespace = 5
	vim.opt.guifont = { "FiraCode Nerd", "Symbols Nerd Font Mono", ":h18" }

	vim.g.neovide_floating_shadow = true
	vim.g.neovide_floating_z_height = 5
	vim.g.neovide_light_angle_degrees = 45
	vim.g.neovide_light_radius = 60

	vim.g.neovide_cursor_vfx_mode = "railgun"
	vim.g.neovide_cursor_vfx_particle_lifetime = 1.5
	vim.g.neovide_cursor_vfx_particle_density = 17.0
	vim.g.neovide_cursor_vfx_particle_phase = 4.5
	vim.g.neovide_cursor_vfx_particle_curl = 4.0
	-- Put anything you want to happen only in Neovide here
end

require("config.options")
require("config.keymaps")
require("config.lazy")
require("config.autocmds")

-- vim.cmd.colorscheme("github_dark_dimmed")
require("themes")

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

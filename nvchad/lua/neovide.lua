-- vim.o.guifont = "FiraCode Nerd Font:h14"
-- vim.opt.linespace = 1
vim.opt.linespace = 5
vim.opt.guifont = "FiraCode Nerd Font:h16"

vim.g.neovide_floating_shadow = true
vim.g.neovide_floating_z_height = 5
vim.g.neovide_light_angle_degrees = 45
vim.g.neovide_light_radius = 60

vim.g.neovide_cursor_vfx_mode = "railgun"
vim.g.neovide_cursor_vfx_particle_lifetime = 1.5
vim.g.neovide_cursor_vfx_particle_density = 17.0
vim.g.neovide_cursor_vfx_particle_phase = 4.5
vim.g.neovide_cursor_vfx_particle_curl = 4.0

-- Helper function for transparency formatting
local alpha = function()
  return string.format("%x", math.floor(255 * (vim.g.transparency or 0.8)))
end
-- g:neovide_transparency should be 0 if you want to unify transparency of content and title bar.
vim.g.neovide_transparency = 0.9
-- vim.g.transparency = 0.8
-- vim.g.neovide_background_color = "#0f1117" .. alpha()
vim.g.neovide_window_blurred = true
vim.g.neovide_floating_blur_amount_x = 10.0
vim.g.neovide_floating_blur_amount_y = 10.0

vim.g.neovide_show_border = true

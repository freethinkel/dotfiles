require("user.options")
require("user.configs.lualine").setup()
require("user.configs.lsp").setup()
require("user.mappings")
require("user.plugins")

require("user.configs.themes").set_theme(require("user.configs.themes").themes.pomandres)


if vim.g.neovide then
  vim.o.guifont = "Iosevka Nerd Font:h16"

  vim.g.neovide_padding_top = 0 -- Set to 40 if the tabline is hidden
  vim.g.neovide_padding_bottom = 0
  vim.g.neovide_padding_right = 30
  vim.g.neovide_padding_left = 30

  vim.g.neovide_floating_blur_amount_x = 2.0
  vim.g.neovide_floating_blur_amount_y = 2.0

  vim.g.neovide_hide_mouse_when_typing = true

  vim.g.neovide_remember_window_size = true
  vim.g.neovide_confirm_quit = true

  vim.g.neovide_fullscreen = false

  vim.g.neovide_input_use_logo = true
  vim.g.neovide_input_macos_alt_is_meta = true

  vim.g.neovide_cursor_antialiasing = false
  vim.g.neovide_cursor_animate_in_insert_mode = true
  vim.g.neovide_cursor_animate_command_line = true
end

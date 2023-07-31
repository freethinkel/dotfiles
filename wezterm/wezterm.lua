local wezterm = require 'wezterm'
local config = {}

config.color_scheme = "Catppuccin Frappe"

config.font = wezterm.font('Iosevka Nerd Font')
config.font_size = 14.0
config.line_height = 1.6
config.window_background_opacity = 0.9
config.macos_window_background_blur = 60
config.enable_tab_bar = false
config.disable_default_key_bindings = true
config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.enable_kitty_keyboard = true

config.keys = {
  { key = 'L', mods = 'CTRL', action = wezterm.action.ShowDebugOverlay },
  { key = "q", mods = "CMD",  action = wezterm.action.CloseCurrentTab({ confirm = false }) },
  { key = "c", mods = "CMD",  action = wezterm.action.CopyTo("Clipboard") },
  { key = "v", mods = "CMD",  action = wezterm.action.PasteFrom("Clipboard") },
  {
    key = "LeftArrow",
    mods = 'ALT',
    action = wezterm.action.SendString('\x1bb'),
  },
  {
    key = "RightArrow",
    mods = 'ALT',
    action = wezterm.action.SendString('\x1bf'),
  },
  -- TMUX WINDOW
  {
    key = "t",
    mods = "CMD",
    action = wezterm.action.SendString("\x02\x63")
  },
  {
    key = "w",
    mods = "CMD",
    action = wezterm.action.SendString("\x02\x78")
  },
  {
    key = '|',
    mods = "CMD|SHIFT",
    action = wezterm.action.SendString("\x02\x25")
  },
  {
    key = "_",
    mods = "CMD|SHIFT",
    action = wezterm.action.SendString("\x02\x22")
  },
  {
    key = "{",
    mods = "CMD|SHIFT",
    action = wezterm.action.SendString("\x02\x70")
  },
  {
    key = "}",
    mods = "CMD|SHIFT",
    action = wezterm.action.SendString("\x02\x6e")
  },
  {
    key = "x",
    mods = "CMD",
    action = wezterm.action.SendString("\x02\x78"),
  },
  {
    key = ",",
    mods = "CMD",
    action = wezterm.action.SendString("\x02\x2c")
  },
  -- tmux select window pane
  { key = "1", mods = "CMD", action = wezterm.action.SendString("\x02\x31") },
  { key = "2", mods = "CMD", action = wezterm.action.SendString("\x02\x32") },
  { key = "3", mods = "CMD", action = wezterm.action.SendString("\x02\x33") },
  { key = "4", mods = "CMD", action = wezterm.action.SendString("\x02\x34") },
  { key = "5", mods = "CMD", action = wezterm.action.SendString("\x02\x35") },
  { key = "6", mods = "CMD", action = wezterm.action.SendString("\x02\x36") },
  { key = "7", mods = "CMD", action = wezterm.action.SendString("\x02\x37") },
  { key = "8", mods = "CMD", action = wezterm.action.SendString("\x02\x38") },
  { key = "9", mods = "CMD", action = wezterm.action.SendString("\x02\x39") },
}
return config

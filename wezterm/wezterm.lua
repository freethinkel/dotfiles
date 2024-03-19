local wezterm = require("wezterm")
local themes = require("themes")

local config = {
	font_size = 13,
	line_height = 1.5,
	font = wezterm.font("FiraCode Nerd Font", {}),
	harfbuzz_features = {
		"zero",
		"cv05",
		"cv14",
		"ss09",
		"cv32",
		"cv31",
		"cv27",
		"cv28",
		"cv30",
		"cv25",
		"ss10",
		"cv06",
	},
	colors = themes.nules_dark,
	window_decorations = "RESIZE",
	hide_tab_bar_if_only_one_tab = true,
	-- enable_tab_bar = false,
	native_macos_fullscreen_mode = true,
	window_close_confirmation = "NeverPrompt",
	adjust_window_size_when_changing_font_size = false,
	debug_key_events = false,
	disable_default_key_bindings = true,
	-- window_background_opacity = 1,
	-- macos_window_background_blur = 20,
	underline_position = "-0.2cell",
	-- background = {
	-- 	{
	-- 		source = { File = { path = "/Users/freethinkel/Developer/dev/dotfiles/wallpapers/pic_1653828646713.jpg" } },
	-- 		height = "Cover",
	-- 		width = "Cover",
	-- 		horizontal_align = "Center",
	-- 		repeat_x = "Repeat",
	-- 		repeat_y = "Repeat",
	-- 		opacity = 1,
	-- 	},
	-- },
	window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	},
	keys = require("mapping"),
	set_environment_variables = {
		TERMINFO_DIRS = "/home/user/.nix-profile/share/terminfo",
		WSLENV = "TERMINFO_DIRS",
	},
	term = "wezterm",
	-- use_ime = false,
	-- default_cursor_style = "SteadyBar",
	-- != =>
	-- ==> == >>== !== !=
	-- ()   () [] []
	-- !~ !==|  |  {. .}
	-- [] ... === !==
}

return config

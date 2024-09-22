local wezterm = require("wezterm")
local M = {}

local current_color_scheme = nil

wezterm.on("window-config-reloaded", function(window, _)
	local overrides = window:get_config_overrides() or {}
	local appearance = window:get_appearance()
	local scheme = appearance:find("Dark") and "Dark" or "Light"

	overrides.colors = scheme == "Dark" and current_color_scheme.dark or current_color_scheme.light
	window:set_config_overrides(overrides)
end)

local get_color_scheme = function()
	if wezterm.gui then
		return wezterm.gui.get_appearance()
	end
	return "Dark"
end

M.get_theme = function(options)
	local system_appearance = get_color_scheme()

	current_color_scheme = options

	if system_appearance == "Dark" then
		return options.dark
	end

	return options.light
end

return M

local wezterm = require("wezterm")
local k = require("utils.keyboard")

return {
	k.send_string("ALT", "LeftArrow", "\x1b\x62"),
	k.send_string("ALT", "RightArrow", "\x1b\x66"),
	k.send_string("CMD", "LeftArrow", "\x01"),
	k.send_string("CMD", "RightArrow", "\x01"),
	k.cmd_to_tmux_prefix("Comma", "Comma"),
	k.cmd_to_tmux_prefix("x", "x"),
	k.cmd_to_tmux_prefix("w", "&"),
	k.cmd_to_tmux_prefix("t", "c"),
	k.cmd_to_tmux_prefix("1", "1"),
	k.cmd_to_tmux_prefix("2", "2"),
	k.cmd_key("q", wezterm.action.QuitApplication),
	k.cmd_key("0", wezterm.action.ResetFontSize),
	-- sdfsd
	-- k.cmd_to_tmux_prefix("_", '"'),
	-- k.send_string("CMD", "_", "\x02\x22"),

	k.send_string("CMD|SHIFT", "_", "\x02\x22"),
	-- k.mapping("CMD", "-", wezterm.action.DecreaseFontSize),
	k.cmd_key("=", wezterm.action.IncreaseFontSize),

	-- CHANGE TMUX TABS
	k.send_string("CMD|SHIFT", "]", "\x02\x6e"),
	k.send_string("CMD|SHIFT", "[", "\x02\x70"),
	k.send_string("CMD|SHIFT", "}", "\x02\x6e"),
	k.send_string("CMD|SHIFT", "{", "\x02\x70"),
	k.send_string("CMD", "}", "\x02\x6e"),
	k.send_string("CMD", "{", "\x02\x70"),
}

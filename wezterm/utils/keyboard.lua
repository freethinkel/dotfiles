local wezterm = require("wezterm")

local M = {}

M.mapping = function(mods, key, action)
	return { key = key, mods = mods, action = action }
end

M.send_string = function(mods, key, strings)
	return M.mapping(mods, key, wezterm.action.SendString(strings))
end

M.cmd_key = function(key, action)
	return M.mapping("CMD", key, action)
end

M.cmd_to_tmux_prefix = function(key, tmux_key)
	return M.mapping(
		"CMD",
		key,
		wezterm.action.Multiple({
			wezterm.action.SendKey({ mods = "CTRL", key = "b" }),
			wezterm.action.SendKey({ key = tmux_key }),
		})
	)
end

return M

-- map cmd+shift+]       send_text all \x02\x6e
-- map cmd+shift+[       send_text all \x02\x70
-- map cmd+|             send_text all \x02\x25
-- map cmd+shift+-       send_text all \x02\x22
-- map cmd+x             send_text all \x02\x78
-- map ctrl+j            no_op
-- map ctrl+i            no_op
-- map ctrl+m            no_op
-- map ctrl+h            no_op
-- map cmd+1             send_text all \x02\x31
-- map cmd+2             send_text all \x02\x32
-- map cmd+3             send_text all \x02\x33
-- map cmd+4             send_text all \x02\x34
-- map cmd+5             send_text all \x02\x35
-- map cmd+6             send_text all \x02\x36
-- map cmd+7             send_text all \x02\x37
-- map cmd+8             send_text all \x02\x38
-- map cmd+9             send_text all \x02\x39

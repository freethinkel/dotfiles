local colors = require("colors")
local is_connected = false

local tailscale = sbar.add("item", {
	icon = {
		string = "􀆪",
		color = colors.foreground,
		font = {
			size = 16.0,
		},
	},
	position = "right",
	update_freq = 10,
})

-- ponytail: grep вместо парсинга json — полный вывод status ~600KB, sbar.exec его не переваривает
function check_connection()
	sbar.exec("/usr/local/bin/tailscale status --json --peers=false | grep BackendState", function(result)
		is_connected = result:match("Running") ~= nil
		tailscale:set({ icon = { color = is_connected and colors.green or colors.red } })
	end)
end

tailscale:subscribe("mouse.clicked", function(env)
	sbar.exec("/usr/local/bin/tailscale " .. (is_connected and "down" or "up"), function()
		check_connection()
	end)
end)

tailscale:subscribe("routine", function()
	check_connection()
end)

check_connection()

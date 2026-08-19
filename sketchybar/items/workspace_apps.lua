local colors = require("colors")

local active_app = sbar.add("item", {
	icon = { drawing = false },
	label = {
		font = {
			style = "Black",
			size = 12.0,
		},
		color = colors.foreground,
	},
})

local other_apps = sbar.add("item", {
	icon = { drawing = false },
	label = {
		font = {
			style = "Medium",
			size = 12.0,
		},
		color = 0x99ffffff,
		padding_left = 0,
	},
	padding_left = 0,
})

-- SbarLua parses JSON output of yabai query into a lua table
local function update_apps(front_app_name)
	sbar.exec("yabai -m query --windows --space", function(windows, _)
		local apps = {}
		local seen = {}
		for _, win in ipairs(windows or {}) do
			local app = win.app
			if app and win["is-visible"] and app ~= front_app_name and not seen[app] then
				seen[app] = true
				table.insert(apps, app)
			end
		end

		active_app:set({ label = { string = front_app_name or "" } })
		other_apps:set({
			label = { string = #apps > 0 and table.concat(apps, "  ") or "" },
		})
	end)
end

local function update_from_focused()
	sbar.exec("yabai -m query --windows --window", function(win, _)
		update_apps(win and win.app or "")
	end)
end

active_app:subscribe("front_app_switched", function(env)
	update_apps(env.INFO)
end)

other_apps:subscribe("space_change", function(_)
	update_from_focused()
end)

-- Initial population
update_from_focused()

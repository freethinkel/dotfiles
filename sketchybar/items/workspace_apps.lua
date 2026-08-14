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

local function update_apps(front_app_name)
	sbar.exec("aerospace list-windows --workspace focused --format '%{app-name}'", function(result, _)
		local apps = {}
		local seen = {}
		for line in result:gmatch("[^\r\n]+") do
			local app = trim(line)
			if app ~= "" and app ~= front_app_name and not seen[app] then
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

active_app:subscribe("front_app_switched", function(env)
	update_apps(env.INFO)
end)

other_apps:subscribe("aerospace_workspace_change", function(_)
	sbar.exec("aerospace list-windows --focused --format '%{app-name}'", function(result, _)
		local focused_app = trim(result)
		update_apps(focused_app)
	end)
end)

-- Initial population
sbar.exec("aerospace list-windows --focused --format '%{app-name}'", function(result, _)
	local focused_app = trim(result)
	update_apps(focused_app)
end)

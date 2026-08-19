local colors = require("colors")

local space_icons = {
	"􀎭",
	"􀡅",
	"􁒙",
	"􀑪",
	"􀈪",
}

local spaces_group = {}

-- yabai uses real macOS spaces, so native "space" items + space_change just work
for key, icon in ipairs(space_icons) do
	local space = sbar.add("space", "space." .. key, {
		space = key,
		icon = {
			string = icon,
			padding_left = 6,
			padding_right = 6,
			color = colors.foreground,
			highlight_color = colors.accent,
		},
		padding_left = 2,
		padding_right = 2,
	})

	spaces_group[key] = space.name -- for brackets

	space:subscribe("space_change", function(env)
		sbar.set(env.NAME, { icon = { highlight = env.SELECTED == "true" } })
	end)
	space:subscribe("mouse.clicked", function()
		sbar.exec("yabai -m space --focus " .. key)
	end)
end

sbar.add("bracket", spaces_group, {
	background = { color = colors.popup_background, border_color = colors.popup_background },
})

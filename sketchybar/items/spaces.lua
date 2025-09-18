local colors = require("colors")

local function mouse_click(index)
	return function()
		sbar.exec("aerospace workspace " .. index)
	end
end

local function space_selection(key)
	return function(env)
		local is_current_workspace = (env.FOCUSED_WORKSPACE .. "") == (key .. "")

		sbar.set(env.NAME, {
			icon = { highlight = is_current_workspace },
		})
	end
end

local space_icons = {
	"􀎭",
	"􀡅",
	"􁒙",
	"􀑪",
	"􀈪",
	"",
	"",
	"",
	"",
}

local spaces_group = {}

sbar.exec("aerospace list-workspaces --all", function(result, _)
	local aerospace_spaces = {}
	result:gsub("%S+", function(word)
		table.insert(aerospace_spaces, word)
	end)

	for key in ipairs(space_icons) do
		if aerospace_spaces[key] == nil then
			sbar.remove(spaces_group[key])
		end
	end

	sbar.exec("aerospace list-workspaces --focused", function(out, _)
		for key in ipairs(spaces_group) do
			local is_current_workspace = tostring(key) == trim(tostring(out))

			if aerospace_spaces[key] ~= nil then
				sbar.set(spaces_group[key], {
					icon = {
						highlight = is_current_workspace, -- Reset highlight for all spaces
					},
				})
			end
		end
	end)
end)

for key in ipairs(space_icons) do
	local space = sbar.add("item", {
		icon = {
			string = space_icons[key],
			padding_left = 6,
			padding_right = 6,
			color = colors.foreground,
			highlight_color = colors.accent,
		},
		padding_left = 2,
		padding_right = 2,
	})

	spaces_group[key] = space.name -- for brackets
	space:subscribe("aerospace_workspace_change", space_selection(key))
	space:subscribe("mouse.clicked", mouse_click(key))
end

sbar.add("bracket", spaces_group, {
	background = { color = colors.popup_background, border_color = colors.popup_background },
})

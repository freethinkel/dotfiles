local colors = require("colors")

local caffeinate = sbar.add("item", {
	icon = {
		string = "􀸘",
		color = colors.foreground,
		font = {
			size = 16.0,
		},
	},
	position = "right",
})

-- ponytail: clamshell красным на подсвеченном фоне — забыть невозможно
local looks = {
	off = { icon = { string = "􀸘", color = colors.foreground }, background = { drawing = false } },
	on = { icon = { string = "􀸙 ", color = colors.yellow }, background = { drawing = false } },
	clamshell = {
		icon = { string = "􀸙 ", color = colors.background },
		background = { drawing = true, color = colors.red, corner_radius = 6, height = 22 },
	},
}

-- ponytail: состояние держим в переменной, sbar.exec давится && и пайпами
local state = "off"

local function apply(next_state)
	if state == "clamshell" then
		sbar.exec("sudo pmset -a disablesleep 0")
	end
	sbar.exec("killall caffeinate")

	if next_state == "on" then
		sbar.exec("caffeinate -di & disown")
	elseif next_state == "clamshell" then
		sbar.exec("sudo pmset -a disablesleep 1")
		sbar.exec("caffeinate -di & disown")
	end

	state = next_state
	caffeinate:set(looks[state])
end

caffeinate:subscribe("mouse.clicked", function(env)
	if state ~= "off" then
		apply("off")
	elseif env.BUTTON == "right" then
		apply("clamshell")
	else
		apply("on")
	end
end)

-- состояние на старте: caffeinate уже мог остаться от прошлой сессии
sbar.exec("pgrep -x caffeinate", function(result)
	state = trim(result) ~= "" and "on" or "off"
	caffeinate:set(looks[state])
end)

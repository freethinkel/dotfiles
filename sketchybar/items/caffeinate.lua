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

-- ponytail: -fx матчит ровно нашу команду целиком, поэтому pkill не заденет
-- ни свой шелл, ни чужие caffeinate от других тулов
local OURS = 'pkill -fx "caffeinate -di"'

local function apply(next_state)
	-- ponytail: одна строка на весь переход — sbar.exec асинхронный,
	-- раздельными вызовами killall гонялся с запуском и убивал новый процесс
	local cmd = OURS
	if state == "clamshell" then
		cmd = cmd .. "; sudo pmset -a disablesleep 0"
	end
	if next_state == "clamshell" then
		cmd = cmd .. "; sudo pmset -a disablesleep 1"
	end
	if next_state ~= "off" then
		cmd = cmd .. "; caffeinate -di &"
	end
	sbar.exec(cmd)

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
sbar.exec('pgrep -fx "caffeinate -di"', function(result)
	state = trim(result) ~= "" and "on" or "off"
	caffeinate:set(looks[state])
end)

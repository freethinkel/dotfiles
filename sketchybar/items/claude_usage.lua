local colors = require("colors")

-- macOS 27 рисует все status items одним окном процесса MenuBarAgent, отдельных
-- окон "Control Center,<item>" в CGWindowList больше нет — sketchybar alias
-- нечего захватывать. Читаем процент прямо из данных Claude Usage.
local usage = sbar.add("item", {
	icon = {
		string = "",
		width = 24,
		background = { drawing = true, color = 0x0, image = { drawing = true, scale = 0.5 } },
	},
	label = { string = "--", color = colors.foreground },
	position = "right",
	update_freq = 30,
})

-- ponytail: один вызов вместо exec внутри exec — вложенный callback у SbarLua
-- молча не срабатывал, картинка застревала на прошлом проценте.
-- Системный python3: у launchd-процесса homebrew в PATH нет.
local CMD = "/usr/bin/python3 " .. os.getenv("HOME") .. "/.config/sketchybar/plugins/claude_usage.py"

local function update()
	sbar.exec(CMD, function(result)
		local pct, png = trim(result):match("^(%d+) (.+)$")
		if pct then
			usage:set({ label = pct .. "%", icon = { background = { image = png } } })
		end
	end)
end

usage:subscribe("routine", update)
update()

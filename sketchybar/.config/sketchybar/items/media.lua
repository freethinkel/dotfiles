local icons = {
	play = "􀊆",
	pause = "􀊄",
}
local media = sbar.add("item", "media", {
	icon = { drawing = false },
	label = { max_chars = 30 },
	padding_right = 30,
	position = "right",
	updates = true,
	update_freq = 3,
	drawing = false,
})

local pid = nil

-- ponytail: media-control, а не встроенный media_change — MediaRemote закрыт для sketchybar с macOS 15.4
local function update_media()
	sbar.exec("media-control get", function(info)
		if type(info) ~= "table" or not info.title then
			pid = nil
			media:set({ drawing = false })
			return
		end
		pid = info.processIdentifier
		local icon = info.playing and icons.play or icons.pause
		local label = info.title
		if info.artist and info.artist ~= "" then
			label = info.artist .. " – " .. label
		end
		media:set({ drawing = true, label = icon .. " " .. label })
	end)
end

media:subscribe("routine", update_media)
media:subscribe("forced", update_media)

media:subscribe("mouse.clicked", function()
	if pid then
		-- ponytail: активируем по pid — работает и для не-.app бинарников
		sbar.exec(
			"osascript -e 'tell application \"System Events\" to set frontmost of (first process whose unix id is "
				.. pid
				.. ") to true'"
		)
	end
end)

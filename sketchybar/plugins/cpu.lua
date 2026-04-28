local colors = require("colors")

local item = sbar.add("item", {
	icon = {
		string = "…",
		color = colors.foreground,
	},
	position = "right",
	updates = true,
	update_freq = 10,
})

local function update()
	sbar.exec(
		[[vm_stat | awk -v total=$(sysctl -n hw.memsize) -v psize=$(pagesize) '
			/Pages active/                 {a=$3+0}
			/Pages wired down/             {w=$4+0}
			/Pages occupied by compressor/ {c=$5+0}
			END { printf "%.0f", (a+w+c)*psize*100/total }']],
		function(result)
			item:set({ icon = { string = result .. "%" } })
		end
	)
end

item:subscribe("routine", update)
item:subscribe("forced", update)

item:subscribe("mouse.clicked", function()
	sbar.exec("open -na Ghostty --args --title=scratch -e 'btop'")
end)

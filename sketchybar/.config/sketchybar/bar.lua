local colors = require("colors")

-- Equivalent to the --bar domain
sbar.bar({
	height = 40,
	color = colors.background,
	-- border_color = colors.bar.border,
	shadow = false,
	sticky = true,
	padding_right = 10,
	padding_left = 10,
	topmost = "window",
})

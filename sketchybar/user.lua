local settings = {
	font = "Iosevka Nerd Font",
}

sbar.default({
	updates = "when_shown",
	icon = {
		font = {
			family = settings.font,
			style = "Bold",
			size = 14.0,
		},
	},
	label = {
		font = {
			family = settings.font,
			style = "Semibold",
			size = 13.0,
		},
	},
})

sbar.bar({
	padding_right = 20,
	padding_left = 20,
})

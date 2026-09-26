local uname = sbar.add("item", "uname", {
	position = "right",
	icon = { drawing = false },
	label = ":: " .. os.getenv("USER") .. " ::",
})

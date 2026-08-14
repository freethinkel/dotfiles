-- The app registers its widget through Control Center, not as its own menu
-- bar item; aliasing "Claude Usage" grabs the popover window instead.
sbar.add("alias", "Control Center,claudeUsageTracker.metric.session", {
	position = "right",
	padding_right = -5,
	-- y_offset = 10,
	alias = {
		-- color = 0xffffffff,
		scale = 1,
	},
})

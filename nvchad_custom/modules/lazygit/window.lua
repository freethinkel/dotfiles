local M = {}

M.open = function()
	local scale = 0.9

	local status, plenary = pcall(require, "plenary.window.float")
	if not status then
		return
	end

	plenary.percentage_range_window(scale, scale, {}, {
		topleft = "╭",
		topright = "╮",
		top = "─",
		left = "│",
		right = "│",
		botleft = "╰",
		botright = "╯",
		bot = "─",
	})
end

return M

local M = {}

M.open_float_window = function()
	local status, plenary = pcall(require, "plenary.window.float")
	if not status then
		return
	end

	plenary.percentage_range_window(1, 1, {}, {
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

local M = {}

M.setup = function()
	local status, gitsigns = pcall(require, "gitsigns")

	if not status then
		return
	end

	gitsigns.setup({
		current_line_blame = true,
	})
end

return M

local M = {}

M.setup = function()
	local status, diffview = pcall(require, "diffview")
	if not status then
		return
	end

	local actions = require("diffview.actions")

	diffview.setup()
end

return M

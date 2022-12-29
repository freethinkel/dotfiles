local M = {}

M.setup = function()
	local status, telescope = pcall(require, "telescope")
	if not status then
		return
	end
	telescope.setup({
		defaults = {
			mappings = {
				n = { ["q"] = require("telescope.actions").close },
			},
		}
	})
end

return M

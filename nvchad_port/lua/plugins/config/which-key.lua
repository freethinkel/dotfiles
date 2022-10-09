local mappings = require("core.mappings")

local M = {}

M.setup = function()
	local status, wk = pcall(require, "which-key")

	if not status then
		return
	end

	wk.register(mappings.which_key.leader, { prefix = "<leader>" })
	wk.register(mappings.which_key.normal)
end

return M

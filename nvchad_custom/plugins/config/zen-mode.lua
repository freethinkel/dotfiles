local M = {}

M.setup = function()
	local status, zen_mode = pcall(require, "zen-mode")
	if not status then
		return
	end

	-- zen_mode.setup()
end

return M

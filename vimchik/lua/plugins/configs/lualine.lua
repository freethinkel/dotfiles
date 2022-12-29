local M = {}

M.setup = function()
	local status, lualine = pcall(require, "lualine")
	if not status then
		return
	end

	lualine.setup({
		options = {
			theme = "auto",
			globalstatus = true
		}
	})
end

return M

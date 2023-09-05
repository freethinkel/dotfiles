local M = {}

M.setup = function()
	print("multi")
	require("multicursors").setup({})
end

return M

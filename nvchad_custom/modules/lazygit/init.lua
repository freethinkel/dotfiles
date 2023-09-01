local M = {}

local state = false
local open_window = require("custom.utils").open_float_window

M.open = function()
	state = true
	open_window()
	vim.fn.termopen("lazygit", { on_exit = M.close })
	vim.cmd("startinsert")
end

M.close = function()
	state = false
	vim.cmd("silent! :q")
end

M.toggle = function()
	if state then
		M.close()
	else
		M.open()
	end
end

return M

local saga = require("lspsaga")

local M = {}

M.setup = function()
	saga.init_lsp_saga({})
end

return M

local icons = require("custom.modules.nonicons.mappings")

local M = {}

M.get = function(name)
	return vim.fn.nr2char(icons[name])
end

return M

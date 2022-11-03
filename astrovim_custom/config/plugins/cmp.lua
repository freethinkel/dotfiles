local M = {}

M.setup = function(config)
	config.source = vim.tbl_deep_extend("force", config.source or {}, { name = "emmet_vim" })

	return config
end

return M

local M = {}

M.setup = function()
	local status, impulse = pcall(require, "impulse")
	if not status then
		return
	end

	impulse.setup({
		api_key = "secret_Cc9jGIBfdYrX1tbs0VBJuLJFcbtX7L4oqKC7zJAj0FE",
		always_refetch = true,
	})
end

return M

local M = {}

M.setup = function()
	require("zen-mode").setup({
		plugins = {
			tmux = { enabled = false }, -- disables the tmux statusline
			kitty = {
				enabled = false,
			},
		},
	})
end

return M

local M = {}

M.setup = function()
	require("zen-mode").setup({
		plugins = {
			tmux = { enabled = true }, -- disables the tmux statusline
			kitty = {
				enabled = true,
				font = "+2", -- font size increment
			},
		},
	})
end

return M

local M = {}

M.setup = function()
	require("zen-mode").setup({
		plugins = {
			tmux = { enabled = true }, -- disables the tmux statusline
			kitty = {
				enabled = true,
				font = "20", -- font size increment
			},
		},
	})
end

return M

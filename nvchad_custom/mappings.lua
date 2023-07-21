---@type MappingsTable
local M = {}

M.general = {
	n = {
		[";"] = { ":", "enter command mode", opts = { nowait = true } },
		["<leader>h"] = { ":nohl<cr>", opts = { silent = true } },
	},
	i = {
		["kj"] = { "<Esc>", "Exit insert mode", opts = { silent = true } },
	},
}

-- more keybinds!

return M

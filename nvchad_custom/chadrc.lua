local M = {}

M.ui = {
	theme = "sweetpastel",
	theme_toggle = { "one_light", "tokyonight" },
	-- transparency = true
}

M.mappings = require("custom.mappings")

M.plugins = {
	user = require("custom.plugins"),
	override = {
		["kyazdani42/nvim-tree.lua"] = require("custom.plugins.nvimtree"),
		["akinsho/bufferline.nvim"] = require("custom.plugins.bufferline"),
		["lewis6991/gitsigns.nvim"] = require("custom.plugins.gitsigns"),
	},
}

return M

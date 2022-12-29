local M = {}

local custom_colors = require("custom.colors")

M.ui = {
	theme = "nord",
	theme_toggle = { "catppuccin", "catppuccin_latte" },
	-- transparency = true,
	hl_add = custom_colors.hl_add(),
	hl_override = custom_colors.hl_override(),
}

M.mappings = require("custom.mappings")

M.plugins = {
	user = require("custom.plugins"),
	-- remove = { "kyazdani42/nvim-web-devicons" },
	override = {
		["hrsh7th/nvim-cmp"] = require("custom.plugins.config.lsp").cmp(),
		-- ["NvChad/ui"] = require("custom.plugins.config.nvchad_ui"),
		["kyazdani42/nvim-tree.lua"] = require("custom.plugins.config.nvimtree"),
		["akinsho/bufferline.nvim"] = require("custom.plugins.config.bufferline"),
		["lewis6991/gitsigns.nvim"] = require("custom.plugins.config.gitsigns"),
		["williamboman/mason.nvim"] = require("custom.plugins.config.mason"),
		["nvim-treesitter/nvim-treesitter"] = {
			auto_install = true,
		},
	},
}

return M

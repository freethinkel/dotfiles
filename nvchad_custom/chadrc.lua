local M = {}

local custom_colors = require("custom.colors")

M.ui = {
	theme = "catppuccin",
	theme_toggle = { "catppuccin", "catppuccin_latte" },
	hl_add = {
		DiffText = {
			fg = "none",
			bg = custom_colors.diff_text,
		},
		-- Gitsigns
		GitSignsAdd = {
			fg = "green",
			bg = "none",
		},
		GitSignsChange = {
			fg = "blue",
			bg = "none",
		},
		GitSignsDelete = {
			fg = "red",
			bg = "none",
		},
		GitWordAdd = {
			bg = custom_colors.diff_text,
		},
		GitWordDelete = {
			bg = custom_colors.diff_text,
		},
		GitSignsAddNr = {
			fg = "green",
			bg = "black",
		},
		GitSignsChangeNr = {
			fg = "blue",
			bg = "black",
		},
		GitSignsDeleteNr = {
			fg = "red",
			bg = "black",
		},
		GitSignsAddLn = {
			fg = "none",
			bg = custom_colors.diff_add,
		},
		GitSignsChangeLn = {
			fg = "none",
			bg = custom_colors.diff_change,
		},
		GitSignsDeleteLn = {
			fg = "none",
			bg = custom_colors.diff_delete,
		},
	},
	hl_override = {
		-- Git
		DiffAdd = {
			fg = "none",
			bg = custom_colors.diff_add,
		},
		DiffChange = {
			fg = "none",
			bg = custom_colors.diff_change,
		},
		DiffDelete = {
			fg = "grey",
			bg = "NONE",
		},
		SignColumn = {
			bg = "black",
		},
		FoldColumn = {
			bg = "black",
		},
	},

	-- transparency = true,
	-- hl_override = {
	-- 	DiffDelete = {
	-- 		fg = "#414141",
	-- 		bg = "NONE",
	-- 	},
	-- vim.cmd(":hi DiffDelete   gui=bold    guifg=#666666")
	-- DiffAdd     diff mode: Added line
	-- DiffChange  diff mode: Changed line
	-- DiffDelete  diff mode: Deleted line
	-- DiffText    diff mode: Changed text within a changed line
	--
	-- hi DiffAdd      gui=none    guifg=NONE          guibg=#bada9f
	-- hi DiffChange   gui=none    guifg=NONE          guibg=#e5d5ac
	-- hi DiffDelete   gui=bold    guifg=#ff8080       guibg=#ffb0b0
	-- hi DiffText     gui=none    guifg=NONE          guibg=#8cbee2
	-- DiffInlineChange
	-- DiffInlineDelete
	-- DiffInlineAdd
	-- },
}

M.mappings = require("custom.mappings")

M.plugins = {
	user = require("custom.plugins"),
	override = {
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

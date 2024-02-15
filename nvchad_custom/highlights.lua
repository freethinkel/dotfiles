-- To find any highlight groups: "<cmd> Telescope highlights"
-- Each highlight group can take a table with variables fg, bg, bold, italic, etc
-- base30 variable names can also be used as colors

local M = {}

M.override_highlights = function()
	local colors = require("base46").get_theme_tb("base_30")
	local hi = require("custom.utils").hi
	local mixColors = require("custom.utils").mixColors

	hi({
		"DiagnosticWarn",
		fg = colors.yellow,
		bg = mixColors(colors.yellow, colors.black, 0.85),
	})
	hi({
		"DiagnosticError",
		fg = colors.red,
		bg = mixColors(colors.red, colors.black, 0.85),
	})
	hi({
		"DiagnosticInfo",
		fg = colors.blue,
		bg = mixColors(colors.blue, colors.black, 0.85),
	})
	hi({
		"DiagnosticHint",
		fg = colors.teal,
		bg = mixColors(colors.teal, colors.black, 0.85),
	})

	hi({
		"DiagnosticSignWarn",
		fg = colors.yellow,
		bg = "NONE",
	})
	hi({
		"DiagnosticSignError",
		fg = colors.red,
		bg = "NONE",
	})
	hi({
		"DiagnosticSignInfo",
		fg = colors.blue,
		bg = "NONE",
	})
	hi({
		"DiagnosticSignHint",
		fg = colors.teal,
		bg = "NONE",
	})
	hi({
		"DiagnosticUnderlineWarn",
		fg = "NONE",
		bg = mixColors(colors.yellow, colors.black, 0.85),
		sp = colors.yellow,
		undercurl = true,
	})
	hi({
		"DiagnosticUnderlineError",
		fg = "NONE",
		bg = mixColors(colors.red, colors.black, 0.85),
		sp = colors.red,
		undercurl = true,
	})
	-- hi({
	-- 	"DiffAdded",
	-- 	fg = "NONE",
	-- 	bg = "green",
	-- })
	hi({
		"diffChanged",
		fg = colors.blue,
	})
	hi({
		"DiffAdd",
		fg = "NONE",
		bg = mixColors(colors.green, colors.black, 0.85),
	})
	hi({
		"DiffDelete",
		fg = "NONE",
		bg = mixColors(colors.red, colors.black, 0.85),
	})
	hi({
		"DiffText",
		fg = "NONE",
		bg = mixColors(colors.green, colors.black, 0.6),
	})
	hi({
		"DiffChange",
		fg = "NONE",
		bg = mixColors(colors.green, colors.black, 0.85),
	})
	hi({
		"DiffDeleteText",
		bg = mixColors(colors.red, colors.black, 0.6),
	})
	hi({
		"DiffAddAsDelete",
		bg = mixColors(colors.red, colors.black, 0.85),
	})
	hi({
		"DiffAddText",
		bg = mixColors(colors.green, colors.black, 0.6),
	})

	-- vim.cmd([[highlight DiffAdd gui=none guifg=none guibg=#103235]])
	-- vim.cmd([[highlight DiffChange gui=none guifg=none guibg=#272D43]])
	-- vim.cmd([[highlight DiffText gui=none guifg=none guibg=#394b70]])
	-- vim.cmd([[highlight DiffDelete gui=none guifg=none guibg=#3F2D3D]])
	-- vim.cmd([[highlight DiffviewDiffAddAsDelete guibg=#3f2d3d gui=none guifg=none]])
	-- vim.cmd([[highlight DiffviewDiffDelete gui=none guifg=#3B4252 guibg=none]])
	--
	-- -- Left panel
	-- -- "DiffChange:DiffAddAsDelete",
	-- -- "DiffText:DiffDeleteText",
	-- vim.cmd([[highlight DiffAddAsDelete gui=none guifg=none guibg=#3F2D3D]])
	-- vim.cmd([[highlight DiffDeleteText gui=none guifg=none guibg=#4B1818]])
	--
	-- -- Right panel
	-- -- "DiffChange:DiffAdd",
	-- -- "DiffText:DiffAddText",
	-- vim.cmd([[highlight DiffAddText gui=none guifg=none guibg=#1C5458]])

	-- FIX GITSIGNS
	hi({
		"GitSignsAdd",
		bg = "NONE",
		fg = colors.green,
	})
	hi({
		"GitSignsAddLn",
		bg = "NONE",
		fg = colors.green,
	})
	hi({
		"GitSignsChange",
		bg = "NONE",
		fg = colors.blue,
	})

	hi({
		"DiagnosticUnderlineInfo",
		fg = "NONE",
		bg = mixColors(colors.blue, colors.black, 0.85),
		sp = colors.blue,
		undercurl = true,
	})
	hi({
		"DiagnosticUnderlineHint",
		fg = "NONE",
		bg = mixColors(colors.teal, colors.black, 0.85),
		sp = colors.teal,
		undercurl = true,
	})
end

---@type Base46HLGroupsList
M.override = {
	Comment = {
		italic = true,
	},
	NvimTreeFolderName = { fg = "grey_fg" },
	NvDashAscii = {
		bg = "none",
		fg = "green",
	},

	FoldColumn = {
		bg = "black",
	},

	-- NvDashButtons = {
	-- 	bg = "none",
	-- 	fg = "light_grey",
	-- },
}

---@type HLTable
M.add = {
	NeoTreeNormal = { link = "NvimTreeNormal" },
	NeoTreeNormalNC = { link = "NvimTreeNormal" },
	NeoTreeWinSeparator = { link = "NvimTreeWinSeparator" },
	NeoTreeDirectoryName = { link = "NvimTreeFolderName" },
	NeoTreeDirectoryIcon = { link = "NvimTreeFolderIcon" },
	NeoTreeGitUntracked = { link = "NvimTreeGitNew" },
	NeoTreeGitUnstaged = {},
	NeoTreeGitAdded = { link = "NvimTreeGitNew" },
	NeoTreeGitModified = { link = "NvimTreeGitDirty" },
	NeoTreeCursorLine = { link = "NvimTreeCursorLine" },
	NeoTreeGitDeleted = { link = "NvimTreeGitDeleted" },
}

return M

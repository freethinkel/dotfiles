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
}

---@type HLTable
M.add = {}

return M

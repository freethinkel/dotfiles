-- To find any highlight groups: "<cmd> Telescope highlights"
-- Each highlight group can take a table with variables fg, bg, bold, italic, etc
-- base30 variable names can also be used as colors

local M = {}

local hi = function(name, options)
	local opt = options or {}
	local bg = opt.bg or "NONE"
	local fg = opt.fg or "NONE"

	vim.cmd("highlight " .. name .. " guifg=" .. fg .. " guibg=" .. bg)
end

local hexToRgb = function(color)
	return {
		tonumber(string.sub(color, 2, 3), 16),
		tonumber(string.sub(color, 4, 5), 16),
		tonumber(string.sub(color, 6, 7), 16),
	}
end

local _mixColorChannel = function(channelA, channelB, amount)
	return (channelA * amount) + (channelB * (1 - amount))
end

local tohex = function(num)
	return string.format("%x", num)
end

local mixColors = function(colorA, colorB, amount)
	colorA = hexToRgb(colorA)
	colorB = hexToRgb(colorB)
	amount = 1 - amount
	local mixed = {
		_mixColorChannel(colorA[1], colorB[1], amount),
		_mixColorChannel(colorA[2], colorB[2], amount),
		_mixColorChannel(colorA[3], colorB[3], amount),
	}

	return "#" .. tohex(mixed[1]) .. tohex(mixed[2]) .. tohex(mixed[3])
end

M.override_hightlight = function()
	local colors = require("base46").get_theme_tb("base_30")

	hi("GitSignsAdd", { fg = colors.green })
	hi("GitSignsAddLn", { fg = colors.blue })
	hi("GitSignsChange", { fg = colors.blue })
	hi("GitSignsDelete", { fg = colors.red })

	hi("DiffAdd", { bg = mixColors(colors.black, colors.green, 0.15) })
	hi("DiffChange", { bg = mixColors(colors.black, colors.blue, 0.15) })
	hi("DiffDelete", { fg = colors.black2 })
	hi("DiffText", { bg = mixColors(colors.black, colors.blue, 0.2) })
	hi("DiffviewDiffAddAsDelete", { bg = mixColors(colors.black, colors.red, 0.15) })
	hi("DiffviewDiffDelete", { fg = colors.black2 })
	vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticSignError", linehl = "", numhl = "" })
	hi("DapBreakpoint", { fg = colors.pink })

	--
	--   {
	--   base00 = "#1a1b26",
	--   base01 = "#16161e",
	--   base02 = "#2f3549",
	--   base03 = "#444b6a",
	--   base04 = "#787c99",
	--   base05 = "#a9b1d6",
	--   base06 = "#cbccd1",
	--   base07 = "#d5d6db",
	--   base08 = "#73daca",
	--   base09 = "#ff9e64",
	--   base0A = "#0db9d7",
	--   base0B = "#9ece6a",
	--   base0C = "#b4f9f8",
	--   base0D = "#2ac3de",
	--   base0E = "#bb9af7",
	--   base0F = "#f7768e"
	-- }

	-- {
	--   baby_pink = "#DE8C92",
	--   black = "#1a1b26",
	--   black2 = "#1f2336",
	--   blue = "#7aa2f7",
	--   cyan = "#7dcfff",
	--   dark_purple = "#9d7cd8",
	--   darker_black = "#16161e",
	--   folder_bg = "#7aa2f7",
	--   green = "#9ece6a",
	--   grey = "#40486a",
	--   grey_fg = "#565f89",
	--   grey_fg2 = "#4f5779",
	--   light_grey = "#545c7e",
	--   lightbg = "#32333e",
	--   line = "#32333e",
	--   nord_blue = "#80a8fd",
	--   one_bg = "#24283b",
	--   one_bg2 = "#414868",
	--   one_bg3 = "#353b45",
	--   orange = "#ff9e64",
	--   pink = "#ff75a0",
	--   pmenu_bg = "#7aa2f7",
	--   purple = "#bb9af7",
	--   red = "#f7768e",
	--   statusline_bg = "#1d1e29",
	--   sun = "#EBCB8B",
	--   teal = "#1abc9c",
	--   vibrant_green = "#73daca",
	--   white = "#c0caf5",
	--   yellow = "#e0af68"
	-- }
end

M.override = {
	CursorLine = {
		bg = "black2",
	},
	Comment = {
		italic = true,
	},
}

---@type HLTable
M.add = {
	NvimTreeOpenedFolderName = { fg = "green", bold = true },
}

M.hi = hi

return M

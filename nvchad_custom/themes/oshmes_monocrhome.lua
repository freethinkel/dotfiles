-- Thanks to original theme for existing https://github.com/microsoft/vscode/blob/main/extensions/theme-defaults/themes/dark_plus.json
-- this is a modified version of it

-- TODO: in progess
local M = {}

M.base_30 = {
	white = "#dee1e6",
	darker_black = "#1a1a1a",
	black = "#1E1E1E", --  nvim bg
	black2 = "#252525",
	one_bg = "#282828",
	one_bg2 = "#313131",
	one_bg3 = "#3a3a3a",
	grey = "#444444",
	grey_fg = "#4e4e4e",
	grey_fg2 = "#585858",
	light_grey = "#626262",
	red = "#F97583",
	baby_pink = "#F97583",
	pink = "#bb7cb6",
	line = "#2e2e2e", -- for lines like vertsplit
	green = "#71efb3",
	green1 = "#4EC994",
	vibrant_green = "#bfd8b2",
	blue = "#9ccaff",
	nord_blue = "#9ccaff",
	yellow = "#D7BA7D",
	sun = "#e1c487",
	purple = "#B392F0",
	dark_purple = "#B392F0",
	teal = "#9ccaff",
	orange = "#FFAB70",
	cyan = "#9ccaff",
	statusline_bg = "#242424",
	lightbg = "#303030",
	pmenu_bg = "#282828",
	folder_bg = "#4e4e4e",
}

M.base_16 = {
	base00 = "#1E1E1E",
	base01 = "#262626",
	base02 = "#344253",
	base03 = "#3C3C3C",
	base04 = "#464646",
	base05 = "#bbbbbb",
	base06 = "#bbbbbb",
	base07 = "#FFFFFF",
	base08 = "#bbbbbb",
	base09 = "#bbbbbb",
	base0A = "#bbbbbb",
	base0B = "#bbbbbb",
	base0C = "#bbbbbb",
	base0D = "#bbbbbb",
	base0E = "#bbbbbb",
	base0F = M.base_30.white,
}

M.polish_hl = {
	["@parameter"] = { fg = M.base_30.white, bold = true },
	["@keyword"] = { fg = M.base_30.white, bold = true },
	["@variable"] = { fg = M.base_30.cyan },
	["@field.key"] = { fg = M.base_30.green1 },
	["@field"] = { fg = M.base_30.white },
	["@keyword.return"] = { fg = M.base_16.base0E },
	["@keyword.function"] = { fg = M.base_30.white },
	["@type.builtin"] = { fg = M.base_16.base0E },
	["Type"] = { fg = M.base_16.base0E },
	["@none"] = { fg = M.base_30.white },
	["@property"] = { fg = M.base_30.white },
	Include = { fg = M.base_30.white, bold = true },
	Normal = { fg = M.base_30.white },
	PmenuSel = { fg = "NONE", bold = true },
	Search = { bg = "#564133", fg = "NONE" },
}

M.type = "dark"

M = require("base46").override_theme(M, "oshmes_monochrome")

return M

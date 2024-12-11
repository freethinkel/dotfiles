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
	base05 = "#F97583",
	base06 = "#E9E9E9",
	base07 = "#FFFFFF",
	base08 = "#B392F0",
	base09 = M.base_30.blue,
	base0A = "#ffab70",
	base0B = "#ffab70",
	base0C = "#9CDCFE",
	base0D = "#B392F0",
	base0E = "#F97583",
	base0F = M.base_30.white,
}

M.polish_hl = {
	["@parameter"] = { fg = M.base_30.blue },
	["@keyword"] = { fg = M.base_30.red, bold = true },
	["@variable"] = { fg = M.base_30.cyan },
	["@field.key"] = { fg = M.base_30.green1 },
	["@field"] = { fg = M.base_30.white },
	["@text"] = { fg = M.base_30.white },
	["@keyword.return"] = { fg = M.base_16.base0E, bold = true },
	["@keyword.function"] = { fg = M.base_30.blue, bold = true },
	["@type.builtin"] = { fg = M.base_30.blue },
	["Type"] = { fg = M.base_30.purple },
	["@none"] = { fg = M.base_30.white },
	["@property"] = { fg = M.base_30.white },
	Include = { fg = M.base_30.red },
	Normal = { fg = M.base_30.white },
	PmenuSel = { fg = "NONE", bold = true },
	Search = { bg = "#564133", fg = "NONE" },
}

M.add_hl = {
	NvimTreeExecFile = { fg = M.base_30.green },
	NvimTreeGitStaged = { fg = M.base_30.green },
	NvimTreeGitNew = { fg = M.base_30.green },
	NvimTreeGitDirty = { fg = M.base_30.orange },
}

M.type = "dark"

M = require("base46").override_theme(M, "oshmes")

return M

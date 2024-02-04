local M = {}

M.base_30 = {
	white = "#ffffff",
	darker_black = "#0e0e0e",
	black = "#101010", --  nvim bg
	black2 = "#171717",
	one_bg = "#1c1c1c",
	one_bg2 = "#262626",
	one_bg3 = "#2f2f2f",
	grey = "#393939",
	grey_fg = "#454545",
	grey_fg2 = "#585858",
	light_grey = "#626262",
	red = "#ff8080",
	baby_pink = "#ff8080",
	pink = "#d8a8ff",
	line = "#2e2e2e", -- for lines like vertsplit
	green = "#99ffe4",
	green1 = "#4EC994",
	vibrant_green = "#bfd8b2",
	blue = "#8ed1ff",
	nord_blue = "#8ed1ff",
	yellow = "#ffc799",
	sun = "#ffc799",
	purple = "#d8a8ff",
	dark_purple = "#d8a8ff",
	teal = "#8ed1ff",
	orange = "#ffc799",
	cyan = "#8ed1ff",
	statusline_bg = "#242424",
	lightbg = "#303030",
	pmenu_bg = "#282828",
	folder_bg = "#4e4e4e",
}

M.base_16 = {
	base00 = M.base_30.black,
	base01 = "#262626",
	base02 = "#344253",
	base03 = "#3C3C3C",
	base04 = "#A0A0A0",
	base05 = "#A0A0A0",
	base06 = "#E9E9E9",
	base07 = "#FFFFFF",
	base08 = "#ffc799",
	base09 = M.base_30.white,
	base0A = "#ffc799",
	base0B = "#99ffe4",
	base0C = "#ffc799",
	base0D = "#ffc799",
	base0E = "#A0A0A0",
	base0F = M.base_30.white,
}

M.polish_hl = {
	["@parameter"] = { fg = M.base_30.white },
	["@keyword"] = { fg = M.base_16.base04 },
	["@variable"] = { fg = M.base_30.white },
	["@field.key"] = { fg = M.base_30.green1 },
	["@field"] = { fg = M.base_30.white },
	["@text"] = { fg = M.base_30.white },
	["@keyword.return"] = { fg = M.base_16.base04 },
	["@keyword.function"] = { fg = M.base_16.base04 },
	["@type.builtin"] = { fg = M.base_30.yellow },
	["Type"] = { fg = M.base_30.yellow },
	["@none"] = { fg = M.base_30.white },
	["@property"] = { fg = M.base_30.white },
	Include = { fg = M.base_30.yellow },
	Normal = { fg = M.base_30.white },
	PmenuSel = { fg = "NONE", bold = true },
	Search = { bg = "#564133", fg = "NONE" },
	["@tag.delimiter"] = { fg = M.base_16.base04 },
}

M.add_hl = {
	NvimTreeExecFile = { fg = M.base_30.green },
	NvimTreeGitStaged = { fg = M.base_30.green },
	NvimTreeGitNew = { fg = M.base_30.green },
	NvimTreeGitDirty = { fg = M.base_30.orange },
	["@tag.attribute.tsx"] = { fg = M.base_16.base04 },
	["@punctuation.special"] = { fg = M.base_16.base04 },
	-- ["@property.tsx"] = { fg = M.base_16.base04 },
}

M.type = "dark"

M = require("base46").override_theme(M, "vesper")

return M

local M = {}

local accent = "#75FB9F"
local syntax_accent = "#9FECB7"

-- // accent:#75FB9F
--
-- "terminal.ansiBlack": "#353535",
-- "terminal.ansiRed": "#ff8080",
-- "terminal.ansiGreen": "#A1FFC1",
-- "terminal.ansiYellow": "#ffc799",
-- "terminal.ansiBlue": "#A9F0FD",
-- "terminal.ansiMagenta": "#d8a8ff",
-- "terminal.ansiCyan": "#87f2ff",
-- "terminal.ansiWhite": "#bbbbbb",
--
-- "terminal.ansiBrightBlack": "#353535",
-- "terminal.ansiBrightRed": "#ff8080",
-- "terminal.ansiBrightGreen": "#A1FFC1",
-- "terminal.ansiBrightYellow": "#ffc799",
-- "terminal.ansiBrightBlue": "#A9F0FD",
-- "terminal.ansiBrightMagenta": "#d8a8ff",
-- "terminal.ansiBrightCyan": "#87f2ff",
-- "terminal.ansiBrightWhite": "#bbbbbb",
--
-- "editorBracketHighlight.foreground1": "#75ffbf",
-- "editorBracketHighlight.foreground2": "#009e6c",
-- "editorBracketHighlight.foreground3": "#75ffbf",
-- "editorBracketHighlight.foreground4": "#009e6c",
-- "editorBracketHighlight.foreground5": "#75ffbf",
-- "editorBracketHighlight.foreground6": "#009e6c"

M.base_30 = {
	white = "#ffffff",
	darker_black = "#181818",
	black = "#1B1B1B", --  nvim bg
	black2 = "#1c1c1c",
	one_bg = "#1f1f1f",
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
	green = accent,
	green1 = "#4EC994",
	vibrant_green = "#bfd8b2",
	blue = "#A9F0FD",
	nord_blue = "#A9F0FD",
	yellow = "#fffeaa",
	sun = "#ffc799",
	purple = "#d8a8ff",
	dark_purple = "#d8a8ff",
	teal = "#A9F0FD",
	orange = "#ffc799",
	cyan = "#87f2ff",
	statusline_bg = "#242424",
	lightbg = "#303030",
	pmenu_bg = "#282828",
	folder_bg = "#4e4e4e",
}

-- A0A0A0

M.base_16 = {
	base00 = M.base_30.black,
	base01 = "#262626",
	base02 = "#35583F",
	base03 = "#3C3C3C",
	base04 = "#A0A0A0",
	base05 = "#A0A0A0",
	base06 = "#E9E9E9",
	base07 = "#A9F0FD",
	base08 = "#FFFFFF", -- just foreground
	base09 = M.base_30.white,
	base0A = syntax_accent,
	base0B = "#fffeaa",
	base0C = syntax_accent,
	base0D = syntax_accent,
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
	["@type.builtin"] = { fg = syntax_accent },
	["Type"] = { fg = M.base_30.white },
	["@none"] = { fg = M.base_30.white },
	["@property"] = { fg = M.base_30.white },
	Include = { fg = M.base_16.base0E },
	Normal = { fg = M.base_30.white },
	PmenuSel = { fg = "NONE", bold = true },
	Search = { bg = "#564133", fg = "NONE" },
	["@tag.delimiter"] = { fg = M.base_16.base04 },
}

M.add_hl = {
	NvimTreeExecFile = { fg = M.base_30.green },
	NvimTreeGitStaged = { fg = M.base_30.green },
	NvimTreeGitNew = { fg = M.base_30.green },
	NvimTreeGitDirty = { fg = M.base_30.yellow },
	["@tag.attribute.tsx"] = { fg = M.base_16.base04 },
	["@punctuation.special"] = { fg = M.base_16.base04 },
	["@punctuation.bracket"] = { fg = "#75ffbf" },
	-- ["@property.tsx"] = { fg = M.base_16.base04 },
}

M.type = "dark"

M = require("base46").override_theme(M, "vesper")

return M

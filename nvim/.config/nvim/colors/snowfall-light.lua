-- Light companion to snowfall.nvim's "snowfall-dark", ported from
-- snowfall-zed's "Snowfall light" theme (themes/theme.json). snowfall.nvim
-- only ships the dark colorscheme, but its themes.highlights module takes
-- any base16-style schema, so this just feeds it zed's light palette.
vim.o.background = "light"
require("themes.highlights").setup({
	schema = {
		base00 = "#FFFFFF",
		base01 = "#e7f2f6", -- cursor, selected file
		base02 = "#e7f2f6", -- Telescope highlight cursor
		base03 = "#bdc1c8", -- Comments, NonText, Indent lines
		base04 = "#8c9197", -- line numbers, folder icons, current folder, folder names
		base05 = "#5c6165", -- operators = => && ||
		base06 = "#1c1c1c", -- Current cursor lines number
		base07 = "#50afce", -- hz
		base09 = "#d59225", -- constants = null, true, Enum values
		base08 = "#5c6165", -- just foreground, markdown titles, variables etc
		base0A = "#d59225", -- types, classes etc
		base0B = "#85b300", -- string
		base0C = "#aaaeb4", -- std types, like string, :?, null
		base0D = "#5c6165", -- properties
		base0E = "#a25cb5", -- type keywords, export, import
		base0F = "#50afce", -- brackets, (), {}, ., :
	},
	colors = {
		red = "#FA7583",
		green = "#85b300",
		blue = "#9BCAFF",
		yellow = "#ec9c62",
		accent = "#88c0d0",
	},
})

---@type ChadrcConfig
local M = {}

-- Path to overriding theme and highlights files
local highlights = require("custom.highlights")

M.ui = {
	theme = "vesper",
	transparency = false,
	theme_toggle = { "vesper", "ayu_light" },
	tabufline = {
		overriden_modules = require("custom.utils").fix_tabufline,
	},
	nvdash = {
		load_on_startup = true,
		header = {
			"        ▓████████████▓        ",
			"       ▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓       ",
			"       █▒▒▒▒▒▒▒▒▒▒▒▒▒▒█       ",
			"       █▒▒▓██▓▒▒▓██▓▒▒█       ",
			"       █▒▒▓██▓▒▒▓██▓▒▒█       ",
			"       █▒▒▒▒▒▒▒▒▒▒▒▒▒▒█       ",
			"       ▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓       ",
			"        ▓████████████▓        ",
		},
		buttons = {
			{ "  Find File", "Spc f f", "Telescope find_files" },
			{ "󰈚  Recent Files", "Spc f o", "Telescope oldfiles" },
			{ "󰈭  Find Word", "Spc f w", "Telescope live_grep" },
			{ "  Bookmarks", "Spc m a", "Telescope marks" },
			{ "  Themes", "Spc t h", "Telescope themes" },
			{ "  Mappings", "Spc c h", "NvCheatsheet" },
			{
				"  Restore Session",
				"s",
				function()
					require("persistence").load()
				end,
			},
		},
	},
	hl_override = highlights.override,
	hl_add = highlights.add,
}

M.plugins = "custom.plugins"

-- check core.mappings for table structure
M.mappings = require("custom.mappings")

pcall(require("custom.highlights").override_highlights)

vim.opt.statusline = "%!v:lua.require('custom.ui.statusline').run()"
return M

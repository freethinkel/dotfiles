---@type ChadrcConfig
local M = {}

-- Path to overriding theme and highlights files
local highlights = require("custom.highlights")

local function getNvimTreeWidth()
	for _, win in pairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.bo[vim.api.nvim_win_get_buf(win)].ft == "neo-tree" then
			return vim.api.nvim_win_get_width(win) + 1
		end
	end
	return 0
end

M.ui = {
	theme = "oshmes",
	transparent = true,
	theme_toggle = { "oshmes", "github_light" },
	tabufline = {
		overriden_modules = function(modules)
			table.remove(modules, 1)
			table.insert(
				modules,
				1,
				"%#NvimTreeNormal#" .. (vim.g.nvimtree_side == "right" and "" or string.rep(" ", getNvimTreeWidth()))
			)
			-- or modules[1] = ""
		end,
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

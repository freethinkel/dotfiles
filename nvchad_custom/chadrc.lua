---@type ChadrcConfig
local M = {}

-- Path to overriding theme and highlights files
local highlights = require("custom.highlights")

M.ui = {
	theme = "catppuccin",
	transparent = true,
	theme_toggle = { "catppuccin", "github_light" },
	nvdash = { load_on_startup = true },
	statusline = {
		theme = "vscode_colored", -- default/vscode/vscode_colored/minimal
		separator_style = "default",
		overriden_modules = nil,
	},
	hl_override = highlights.override,
	hl_add = highlights.add,
}

M.plugins = "custom.plugins"

-- check core.mappings for table structure
M.mappings = require("custom.mappings")

pcall(require("custom.highlights").override_highlights)

return M

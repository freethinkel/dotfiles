---@type ChadrcConfig
local M = {}

-- Path to overriding theme and highlights files
local highlights = require("custom.highlights")

M.ui = {
	theme = "tokyonight",
	theme_toggle = { "tokyonight", "one_light" },

	hl_override = highlights.override,
	hl_add = highlights.add,
	nvdash = {
		load_on_startup = true,
	},
}

M.plugins = "custom.plugins"

M.mappings = require("custom.mappings")

return M

---@type ChadrcConfig
local M = {}

-- Path to overriding theme and highlights files
local highlights = require("custom.highlights")

M.ui = {
	theme = "oshmes",
	transparent = true,
	theme_toggle = { "oshmes", "github_light" },
	nvdash = { load_on_startup = true },
	tabufline = {
		enabled = false,
	},
	-- statusline = {
	-- 	enabled = false,
	-- 	theme = "vscode_colored", -- default/vscode/vscode_colored/minimal
	-- 	separator_style = "default",
	-- 	overriden_modules = function(modules)
	-- 		modules[1] = modules[1] .. "%#St_Mode#"
	-- 		-- comp.separator = left and { right = '' } or { left = '' }
	-- 	end,
	-- },
	hl_override = highlights.override,
	hl_add = highlights.add,
}

M.plugins = "custom.plugins"

-- check core.mappings for table structure
M.mappings = require("custom.mappings")

pcall(require("custom.highlights").override_highlights)

vim.opt.statusline = "%!v:lua.require('custom.ui.statusline').run()"
return M

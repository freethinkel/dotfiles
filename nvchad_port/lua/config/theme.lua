local M = {}

local setup_theme = function()
	local utils = require("core.utils")
	local hi = utils.hi
	local hi_link = utils.hi_link
	local bg = vim.o.bg

	vim.g.tokyonight_style = "night"
	vim.g.tokyonight_colors = {
		["bg_dark"] = "#16161F",
		["bg_popup"] = "#16161F",
		["bg_statusline"] = "#16161F",
		["bg_sidebar"] = "#16161F",
		["bg_float"] = "#16161F",
	}

	hi_link("ColorColumn", "CursorLine")
	if bg == "dark" then
		hi("DiffAdd", { bg = "#283B4D", fg = "NONE" })
		hi("DiffChange", { bg = "#28304d", fg = "NONE" })
		hi("DiffText", { bg = "#36426b", fg = "NONE" })
	end
	hi_link("GitsignsAdd", "String")
end

M.setup = function()
	--pcall(setup_theme)
	-- setup_theme()
end

return M

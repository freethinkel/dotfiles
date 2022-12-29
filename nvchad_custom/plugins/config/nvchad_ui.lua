local get_icon = require("custom.modules.nonicons.icons").get

local modes = {
	["n"] = get_icon("vim-normal-mode"),
	["niI"] = get_icon("vim-normal-mode"),
	["niR"] = get_icon("vim-normal-mode"),
	["niV"] = get_icon("vim-normal-mode"),
	["no"] = get_icon("vim-normal-mode"),
	["i"] = get_icon("vim-insert-mode"),
	["ic"] = get_icon("vim-insert-mode"),
	["ix"] = get_icon("vim-insert-mode"),
	["t"] = get_icon("vim-terminal-mode"),
	["nt"] = get_icon("vim-terminal-mode"),
	["v"] = get_icon("vim-visual-mode"),
	["V"] = get_icon("vim-visual-mode"),
	["Vs"] = get_icon("vim-visual-mode"),
	[""] = get_icon("vim-visual-mode"),
	["R"] = get_icon("vim-replace-mode"),
	["Rv"] = get_icon("vim-replace-mode"),
	["s"] = get_icon("vim-select-mode"),
	["S"] = get_icon("vim-select-mode"),
	[""] = get_icon("vim-select-mode"),
	["c"] = get_icon("vim-command-mode"),
	["cv"] = get_icon("vim-command-mode"),
	["ce"] = get_icon("vim-command-mode"),
	["r"] = get_icon("diff-ignored"),
	["rm"] = get_icon("diff-ignored"),
	["r?"] = get_icon("diff-ignored"),
	["!"] = get_icon("vim-terminal-mode"),
}

return {
	statusline = {
		separator_style = "default",
		overriden_modules = function()
			local st_modules = require("nvchad_ui.statusline.modules")
			return {
				mode = function()
					local m = vim.api.nvim_get_mode().mode
					local current_mode = st_modules.mode()
					current_mode = current_mode:gsub(" ", modes[m] .. "  ")
					return current_mode .. "  "
				end,
			}
		end,
	},
}

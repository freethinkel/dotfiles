local M = {}

M.setup = function()
	local status, diffview = pcall(require, "diffview")
	if not status then
		return
	end

	local actions = require("diffview.actions")

	---@diagnostic disable-next-line: redundant-parameter
	diffview.setup({
		diff_binaries = false, -- Show diffs for binaries
		enhanced_diff_hl = true, -- See ':h diffview-config-enhanced_diff_hl'
		use_icons = true, -- Requires nvim-web-devicons
		icons = { -- Only applies when use_icons is true.
			folder_closed = "",
			folder_open = "",
		},
		signs = {
			fold_closed = "",
			fold_open = "",
		},
		file_panel = {
			listing_style = "tree", -- One of 'list' or 'tree'
			tree_options = { -- Only applies when listing_style is 'tree'
				flatten_dirs = false, -- Flatten dirs that only contain one single dir
				folder_statuses = "never", -- One of 'never', 'only_folded' or 'always'.
			},
			directory_statuses = "never",
			win_config = { -- See ':h diffview-config-win_config'
				position = "left",
				width = 35,
			},
		},
		hooks = {
			view_opened = function()
				local custom_colors = require("custom.colors")
				require("indent_blankline.commands").disable()
				vim.cmd("hi DiffviewDiffAddAsDelete guifg=NONE guibg=" .. custom_colors.diff_delete)
			end,
		}, -- See ':h diffview-config-hooks'
	})
end

return M

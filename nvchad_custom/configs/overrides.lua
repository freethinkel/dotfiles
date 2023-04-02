local M = {}

M.treesitter = {
	ensure_installed = {
		"vim",
		"lua",
		"html",
		"css",
		"javascript",
		"c",
		"markdown",
		"markdown_inline",
	},
	auto_install = true,
	indent = {
		enable = true,
		disable = {
			"python",
		},
	},
}

-- git support in nvimtree
M.nvimtree = {
	git = {
		enable = true,
		ignore = false,
	},

	filters = {
		dotfiles = false,
	},
	renderer = {
		highlight_git = true,
		highlight_opened_files = "none",
		indent_markers = {
			enable = true,
			icons = {
				corner = "└",
				edge = "│ ",
				none = "  ",
			},
		},
		icons = {
			webdev_colors = true,
			git_placement = "signcolumn",
			padding = "  ",
			symlink_arrow = " ➛ ",
			show = {
				file = true,
				folder = true,
				folder_arrow = false,
				git = false,
			},
		},
	},
}

M.gitsigns = {
	signs = {
		add = { hl = "GitSignsAddLn", text = "▍", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
		change = { hl = "GitSignsChange", text = "▍", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
		delete = { hl = "GitSignsDelete", text = "▍", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
		topdelete = { hl = "GitSignsDelete", text = "▍", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
		changedelete = { hl = "GitSignsChange", text = "▍", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
		untracked = { hl = "GitSignsAdd", text = "▍", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
	},
	current_line_blame = true,
}

return M

return {
	-- Here is a more advanced example where we pass configuration
	-- options to `gitsigns.nvim`. This is equivalent to the following lua:
	--    require('gitsigns').setup({ ... })
	--
	-- See `:help gitsigns` to understand what the configuration keys do
	{ -- Adds git related signs to the gutter, as well as utilities for managing changes
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "▍" },
				change = {
					text = "▍",
				},
				delete = {
					text = "󰐊",
				},
				topdelete = {
					text = "󰐊",
				},
				changedelete = {
					text = "▍",
				},
				untracked = { text = "▍" },
			},
			-- signs = {
			-- 	add = { hl = "GitSignsAddLn", text = "▍", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
			-- 	change = {
			-- 		hl = "GitSignsChange",
			-- 		text = "▍",
			-- 		numhl = "GitSignsChangeNr",
			-- 		linehl = "GitSignsChangeLn",
			-- 	},
			-- 	delete = {
			-- 		hl = "GitSignsDelete",
			-- 		text = "󰐊",
			-- 		numhl = "GitSignsDeleteNr",
			-- 		linehl = "GitSignsDeleteLn",
			-- 	},
			-- 	topdelete = {
			-- 		hl = "GitSignsDelete",
			-- 		text = "󰐊",
			-- 		numhl = "GitSignsDeleteNr",
			-- 		linehl = "GitSignsDeleteLn",
			-- 	},
			-- 	changedelete = {
			-- 		hl = "GitSignsChange",
			-- 		text = "▍",
			-- 		numhl = "GitSignsChangeNr",
			-- 		linehl = "GitSignsChangeLn",
			-- 	},
			-- 	untracked = { hl = "GitSignsAdd", text = "▍", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
			-- },
			current_line_blame = true,
		},
	},
}

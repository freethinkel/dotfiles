local M = {}
local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap

-- INSERT REMAP
keymap("i", "jk", "<ESC>", opts)
keymap("i", "jj", "<ESC>", opts)
keymap("i", "kj", "<ESC>", opts)
keymap("n", "+", "<C-a>", opts)
keymap("n", "-", "<C-x>", opts)
keymap("n", "ss", ":split<Return>", opts)
keymap("n", "vs", ":vsplit<Return>", opts)

-- Delete word backward
-- keymap('n', 'dw', 'vb"_d', opts)

M.base = {
	n = {
		["<leader>qq"] = {
			"<cmd>:qa!<cr>",
			"Close vim",
		},
	},
}

M.todocomments = {
	n = {
		["tl"] = {
			"<Cmd>TodoTelescope<cr>",
			"Show todos and fixme comments",
		},
	},
}

M.lazygit = {
	n = {
		["<leader>gl"] = {
			function()
				-- require("nvterm.terminal").toggle("float")
				require("custom.modules.lazygit").toggle()
			end,
			"Open lazygit",
		},
	},
}

M.tabufline = {
	n = {
		-- cycle through buffers
		["<S-l>"] = {
			function()
				require("nvchad_ui.tabufline").tabuflineNext()
			end,
			"goto next buffer",
		},

		["<S-h>"] = {
			function()
				require("nvchad_ui.tabufline").tabuflinePrev()
			end,
			"goto prev buffer",
		},
	},
}

return M

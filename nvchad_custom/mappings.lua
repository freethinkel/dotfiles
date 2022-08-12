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

M.todocomments = {
	n = {
		["tl"] = {
			"<Cmd>TodoTelescope<cr>",
			"Show todos and fixme comments",
		},
	},
}

M.tabufline = {
	n = {
		-- cycle through buffers
		["<S-l>"] = {
			function()
				require("core.utils").tabuflineNext()
			end,
			"goto next buffer",
		},

		["<S-h>"] = {
			function()
				require("core.utils").tabuflinePrev()
			end,
			"goto prev buffer",
		},
	},
}

M.lspconfig = {
	i = {
		["<C-k>"] = {
			"<Cmd>Lspsaga signature_help<cr>",
			"Lsp show signature",
		},
	},
	n = {
		["d]"] = {
			"<Cmd>Lspsaga diagnostic_jump_next<cr>",
			"Lsp diagnostics info",
		},
		["d["] = {
			"<Cmd>Lspsaga diagnostic_jump_prev<cr>",
			"Lsp diagnostics info",
		},
		["gd"] = {
			"<Cmd>Lspsaga lsp_finder<cr>",
			"Lsp show definition and references", -- press o - for open file
		},
		["gp"] = {
			"<Cmd>Lspsaga preview_definition<cr>",
			"Lsp preview definition",
		},
		["gr"] = {
			"<Cmd>Lspsaga rename<cr>",
			"Lsp rename",
		},
		["<S-k>"] = {
			"<Cmd>Lspsaga hover_doc<cr>",
			"Lsp hover",
		},
	},
}

return M

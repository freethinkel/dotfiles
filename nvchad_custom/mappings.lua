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

M.disabled = {
	n = {
		["<leader>ca"] = "",
		["[d"] = "",
		["d]"] = "",
	},
}

M.base = {
	n = {
		["<leader>h"] = {
			"<cmd>nohlsearch<cr>",
			"Remove hightlights",
		},
		["<leader>qq"] = {
			"<cmd>:qa!<cr>",
			"Close vim",
		},
		["<leader>uc"] = {
			function()
				vim.cmd("source ~/.config/nvim/init.lua")
			end,
			"update config",
		},
	},
}

M.lsp = {
	n = {
		["gd"] = {
			function()
				vim.cmd("Lspsaga lsp_finder")
			end,
			"Go to definition",
		},
		["K"] = {
			"<Cmd>Lspsaga hover_doc<cr>",
			"Hover lsp",
		},
		["<leader>lr"] = {
			"<cmd>Lspsaga rename<cr>",
			"Rename symbol",
		},
		["<leader>la"] = {
			"<Cmd>Lspsaga code_action<cr>",
			"Lsp code action",
		},
		["<leader>lp"] = {
			"<cmd>Lspsaga peek_definition<cr>",
			"Peek definition",
		},
		["<leader>lk"] = {
			"<cmd>Lspsaga diagnostic_jump_prev<cr>",
			"Lsp diagnostic jump next",
		},
		["<leader>lj"] = {
			"<cmd>Lspsaga diagnostic_jump_next<cr>",
			"Lsp diagnostic jump next",
		},
	},
}

M.spectre = {
	n = {
		["<leader>fr"] = {
			function()
				require("spectre").open()
			end,
			"Find and replace",
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

M.git = {
	n = {
		["<leader>gl"] = {
			function()
				require("custom.modules.lazygit").toggle()
			end,
			"Open lazygit",
		},
		["<leader>gm"] = {
			function()
				local view = require("diffview.lib").get_current_view()
				if view then
					vim.cmd("DiffviewClose")
				else
					vim.cmd("DiffviewOpen")
				end
			end,
			"Toggle Diffview",
		},
	},
}

M.tabufline = {
	n = {
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

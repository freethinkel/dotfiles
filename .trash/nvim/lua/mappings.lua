local nvmap = vim.keymap.set
local map = require("configs.which_key").register

vim.g.mapleader = " "

nvmap("i", "jj", "<Esc>", { silent = true })
nvmap("i", "jk", "<Esc>", { silent = true })
nvmap("i", "kj", "<Esc>", { silent = true })
nvmap("v", "p", 'p:let @+=@0<CR>:let @"=@0<CR>', { silent = true })

map({
	["<leader>e"] = { ":NeoTreeFocusToggle<cr>", "Explorer" },
	["<leader>h"] = { ":nohlsearch<cr>", "Clear highlights" },
})

map({
	["<leader>f"] = {
		name = "Telescope",
		["f"] = {
			function()
				require("telescope.builtin").find_files()
			end,
			"Find files",
		},
		["w"] = {
			function()
				require("telescope.builtin").live_grep()
			end,
			"Find words",
		},
		["r"] = {
			function()
				require("telescope.builtin").oldfiles()
			end,
			"Recents",
		},
	},
})

map({
	["<leader>/"] = {
		function()
			require("Comment.api").toggle.linewise.current()
		end,
		"Toggle comment",
	},
})

map({
	["<leader>/"] = {
		"<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
		"Toggle comment",
	},
}, { mode = "v" })

-- LSP
map({
	["<leader>l"] = {
		name = "LSP",
		["a"] = { "<cmd>Lspsaga code_action<cr>", "Code action" },
		["c"] = { "<cmd>Lspsaga show_cursor_diagnostics<cr>", "Cursor diagnistic" },
		["r"] = { "<cmd>Lspsaga rename<cr>", "Rename" },
		["j"] = { "<cmd>Lspsaga diagnostic_jump_next<cr>", "Next diagnistic" },
		["k"] = { "<cmd>Lspsaga diagnostic_jump_prev<cr>", "Prev diagnistic" },
	},
})

map({
	["g"] = {
		["d"] = { "<cmd>Lspsaga goto_definition<cr>", "Goto definition" },
		["p"] = { "<cmd>Lspsaga peek_definition<cr>", "Peek definition" },
		["r"] = { "<cmd>Lspsaga lsp_finder<cr>", "Lsp finder" },
	},
	["K"] = { "<cmd>Lspsaga hover_doc<cr>", "LSP Hover" },
})

map({
	["<leader>F"] = {
		name = "Flutter",
		["r"] = { ":FlutterRun<cr>", "FlutterRun" },
		["q"] = { ":FlutterQuit<cr>", "FlutterQuit" },
		["c"] = { ":FlutterLogClear<cr>", "FlutterLogClear" },
		["R"] = { ":FlutterRestart<cr>", "FlutterRestart" },
		["e"] = { ":FlutterEmulators<cr>", "FlutterEmulators" },
	},
})

---@type MappingsTable
local M = {}

M.disabled = {
	n = {
		["<leader>x"] = "",
	},
}

M.general = {
	n = {
		[";"] = { ":", "enter command mode", opts = { nowait = true } },
		["<leader>h"] = { ":nohl<cr>", "", opts = { nowait = true, silent = true } },
		-- Move current line / block with Alt-j/k a la vscode.
		["<A-j>"] = { ":m .+1<CR>==", "Move down" },
		["<A-k>"] = { ":m .-2<CR>==", "Move up" },
		["<leader>qq"] = { ":qa!<cr>" },
	},
	i = {
		["jj"] = { "<Esc>", "Exit insert mode", opts = { silent = true } },
		["jk"] = { "<Esc>", "Exit insert mode", opts = { silent = true } },
		["kj"] = { "<Esc>", "Exit insert mode", opts = { silent = true } },
	},
	x = {
		["<A-j>"] = { ":m '>+1<CR>gv-gv", "Move down", opts = { noremap = true, silent = true } },
		["<A-k>"] = { ":m '<-2<CR>gv-gv", "Move up", opts = { noremap = true, silent = true } },
	},
	v = {
		["<"] = { "<gv", "", opts = { noremap = true, silent = true } },
		[">"] = { ">gv", "", opts = { noremap = true, silent = true } },
	},
}

M.tabs = {
	n = {
		["<leader>c"] = {
			function()
				require("nvchad.tabufline").close_buffer()
			end,
			"Close buffer",
		},
		["<S-h>"] = {
			function()
				require("nvchad.tabufline").tabuflinePrev()
			end,
			"Prev tab",
			{ silten = true },
		},
		["<S-l>"] = {
			function()
				require("nvchad.tabufline").tabuflineNext()
			end,
			"Next tab",
			{ silten = true },
		},
	},
}

M.lazygit = {
	n = {
		["<leader>gg"] = {
			function()
				require("custom.modules.lazygit").toggle()
			end,
			"Open lazygit",
		},
	},
}

M.lsp = {
	n = {
		["<leader>la"] = { vim.lsp.buf.code_action, opts = { silent = true, nowait = true } },
	},
}

M.flutter = {
	n = {
		["<leader>FF"] = {
			function()
				require("telescope").extensions.flutter.commands()
			end,
			"Flutter commands",
		},
		["<leader>Fe"] = { ":FlutterEmulators<cr>", "FlutterEmulators" },
		["<leader>Fr"] = { ":FlutterRun<cr>", "FlutterRun" },
		["<leader>Fq"] = { ":FlutterQuit<cr>", "FlutterQuit" },
		["<leader>FR"] = { ":FlutterRestart<cr>", "FlutterRestart" },
		["<leader>FC"] = { ":FlutterLogClear<cr>", "FlutterLogClear" },
	},
}

M.hop = {
	n = {
		["fw"] = { ":HopChar1<cr>", "Activate hop" },
	},
}

M.spectre = {
	n = {
		["<leader>fr"] = {
			function()
				require("spectre").open()
			end,
			"Spectre",
		},
	},
}

M.dap = {
	plugin = true,
	n = {
		["<leader>du"] = {
			function()
				require("dapui").toggle()
			end,
			"Toggle dap ui",
		},
	},
}

return M

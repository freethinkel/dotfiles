---@type MappingsTable
local M = {}

M.disabled = {
	n = {
		["<leader>x"] = "",
		["<leader>f"] = "",
		["<leader>ra"] = "",
		["<C-n>"] = "",
		["[d"] = "",
		["]d"] = "",
		-- for tmux plugin navigation
		["<C-j>"] = "",
		["<C-k>"] = "",
		["<C-h>"] = "",
		["<C-l>"] = "",
	},
}

M.general = {
	i = {
		["jj"] = { "<Esc>", "Exit insert mode", opts = { silent = true } },
		["jk"] = { "<Esc>", "Exit insert mode", opts = { silent = true } },
		["kj"] = { "<Esc>", "Exit insert mode", opts = { silent = true } },
	},
	n = {
		[";"] = { ":", "enter command mode", opts = { nowait = true } },
		["<leader>h"] = { ":nohl<cr>", "", opts = { nowait = true, silent = true } },
		-- Move current line / block with Alt-j/k a la vscode.
		["<A-j>"] = { ":m .+1<CR>==", "Move down" },
		["<A-k>"] = { ":m .-2<CR>==", "Move up" },
		["<leader>qq"] = { ":qa!<cr>" },
		["qq"] = { ":q!<cr>" },
		["<leader>tt"] = {
			function()
				require("base46").toggle_theme()
			end,
			"Toggle theme",
		},
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

M.neotree = {
	plugin = true,

	n = {
		-- toggle
		["<C-n>"] = { "<cmd> Neotree toggle <CR>", "Toggle neotree" },

		-- focus
		["<leader>e"] = { "<cmd> Neotree <CR>", "Focus neotree" },
	},
}

M.zenmode = {
	n = {
		["<leader>zz"] = {
			function()
				require("zen-mode").toggle()
			end,
		},
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

M.lsp = {
	n = {
		["<leader>lf"] = {
			function()
				vim.diagnostic.open_float({ border = "rounded" })
			end,
			"Floating diagnostic",
		},
		["<leader>lk"] = {
			function()
				vim.diagnostic.goto_prev({ float = { border = "rounded" } })
			end,
			"Goto prev",
		},

		["<leader>lj"] = {
			function()
				vim.diagnostic.goto_next({ float = { border = "rounded" } })
			end,
			"Goto next",
		},
		["<leader>lr"] = {
			vim.lsp.buf.rename,
			"LSP rename",
		},
		["<leader>la"] = { vim.lsp.buf.code_action, opts = { silent = true, nowait = true } },
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
		["<leader>dt"] = { "<cmd>DapToggleBreakpoint<cr>", "Toggle breakpoint" },
		["<leader>du"] = {
			function()
				require("dapui").toggle()
			end,
			"Toggle dap ui",
		},
	},
}

vim.api.nvim_create_autocmd("FileType", {
	pattern = "nvdash",
	callback = function(data)
		vim.keymap.set("n", "s", function()
			require("persistence").load()
		end, {
			buffer = data.buf,
		})
	end,
})

-- M.harpoon = {
-- 	-- plugin = true,
-- 	n = {
-- 		["<leader>H"] = {
-- 			function()
-- 				require("harpoon.ui").toggle_quick_menu()
-- 			end,
-- 		},
-- 		["M"] = {
-- 			function()
-- 				require("harpoon.mark").add_file()
-- 			end,
-- 		},
-- 		["H"] = {
-- 			function()
-- 				require("harpoon.ui").nav_next()
-- 			end,
-- 		},
-- 		["L"] = {
-- 			function()
-- 				require("harpoon.ui").nav_prev()
-- 			end,
-- 		},
-- 	},
-- }

return M

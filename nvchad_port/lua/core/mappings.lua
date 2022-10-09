-- n, v, i, t = mode names

local function termcodes(str)
	return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local M = {}

M.mappings = {
	i = {
		["jj"] = "<ESC>",
		["jk"] = "<ESC>",
		["kj"] = "<ESC>",
		["<C-k>"] = "<Cmd>Lspsaga signature_help<cr>",
	},
	n = {
		["+"] = "<C-a>",
		["-"] = "<C-x>",
		["ss"] = ":split<Return>",
		["vs"] = ":vsplit<Return>",
		["<C-j>"] = "<Cmd>Lspsaga diagnostic_jump_next<cr>",
		["<C-k>"] = "<Cmd>Lspsaga signature_help<cr>",
		["<A-i>"] = "<Cmd>FloatermToggle<cr>",
	},
	v = {
		["<leader>/"] = "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
	},
	t = {
		["<C-x>"] = termcodes("<C-\\><C-N>"),
		["<A-i>"] = "<Cmd>FloatermToggle<cr>",
	},
}

M.which_key = {
	leader = {
		["/"] = {
			function()
				require("Comment.api").toggle.linewise.current()
			end,
			"toggle comment",
		},

		h = { "<Cmd>nohlsearch<cr>", "Hide search highlight" },
		x = {
			function()
				local bufnr = vim.api.nvim_get_current_buf()
				vim.cmd("BufferLineCyclePrev")
				vim.cmd("bd" .. bufnr)
			end,
			"Close buffer",
		},
		e = {
			function()
				vim.cmd("NvimTreeFocus")
				require("alpha").redraw()
			end,
			"Explorer",
		},
		f = {
			name = "Find more",
			f = { "<Cmd>Telescope find_files<cr>", "Find files" },
			w = { "<Cmd>Telescope live_grep<cr>", "Find words" },
		},
		n = {
			name = "Editor commands",
			t = {
				"<Cmd>Telescope colorscheme<cr>",
				"Show themes",
			},
			r = {
				function()
					vim.cmd("%source")
					vim.cmd("PackerSync")
				end,
				"Reload config",
			},
			i = {
				function()
					vim.cmd("MasonInstallAll")
				end,
				"Install all lsp servers",
			},
		},
		t = {
			name = "Terminal",
			f = {
				function()
					require("core.utils").toggle_float_terminal()
				end,
				"Open floating terminal",
			},
		},
		p = {
			name = "Packer",
			s = { "<Cmd>PackerSync <cr>", "PackerSync" },
		},
		g = {
			name = "Git",
			m = {
				function()
					local view = require("diffview.lib").get_current_view()
					if view then
						vim.cmd("DiffviewClose")
					else
						vim.cmd("DiffviewOpen")
					end
				end,
				"Git manager",
			},
		},
	},
	normal = {
		K = { "<Cmd>Lspsaga hover_doc<cr>", "Hover doc" },
		g = {
			name = "+Lsp stuff",
			d = { "<Cmd>Lspsaga lsp_finder<cr>", "Goto definition" },
			p = { "<Cmd>Lspsaga preview_definition<cr>", "Preview definition" },
			r = { "<Cmd>Lspsaga rename<cr>", "Rename symbol" },
			a = { "<Cmd>Lspsaga code_action<cr>", "Show code actions" },
			s = { "<Cmd>SymbolsOutline<cr>", "Symbols outline" },
		},
		L = { "<Cmd>BufferLineCycleNext<cr>", "Next buffer" },
		H = { "<Cmd>BufferLineCyclePrev<cr>", "Prev buffer" },
	},
}

return M

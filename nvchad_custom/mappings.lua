---@type MappingsTable
local M = {}

M.disabled = {
	n = {
		["<leader>ca"] = {},
	},
}

M.general = {
	i = {
		["kj"] = { "<Esc>", "Exit to normal mode" },
	},
	n = {
		[";"] = { ":", "enter command mode", opts = { nowait = true } },
		["<leader>h"] = { ":nohl<cr>", "No hightlight" },
	},
}

M.lsp = {
	n = {
		["<leader>la"] = { "<cmd>Lspsaga code_action<cr>", "Code action" },
		["<leader>lc"] = { "<cmd>Lspsaga show_cursor_diagnostics<cr>", "Cursor diagnistic" },
		["<leader>lr"] = { "<cmd>Lspsaga rename<cr>", "Rename" },
		["<leader>lj"] = { "<cmd>Lspsaga diagnostic_jump_next<cr>", "Next diagnistic" },
		["<leader>lk"] = { "<cmd>Lspsaga diagnostic_jump_prev<cr>", "Prev diagnistic" },
		["gd"] = { "<cmd>Lspsaga goto_definition<cr>", "Goto definition" },
		["gp"] = { "<cmd>Lspsaga peek_definition<cr>", "Peek definition" },
		["gr"] = { "<cmd>Lspsaga lsp_finder<cr>", "Lsp finder" },
		["K"] = { "<cmd>Lspsaga hover_doc<cr>", "LSP Hover" },
	},
}

M.flutter = {
	n = {
		["<leader>Fr"] = { ":FlutterRun<cr>", "FlutterRun" },
		["<leader>Fq"] = { ":FlutterQuit<cr>", "FlutterQuit" },
		["<leader>Fc"] = { ":FlutterLogClear<cr>", "FlutterLogClear" },
		["<leader>FR"] = { ":FlutterRestart<cr>", "FlutterRestart" },
		["<leader>Fe"] = { ":FlutterEmulators<cr>", "FlutterEmulators" },
	},
}

M.git = {
	n = {
		["<leader>gg"] = {
			function()
				require("custom.modules.lazygit").toggle()
			end,
			"Open lazygit",
		},
    ["<leader>gh"] = {
      function()
				local view = require("diffview.lib").get_current_view()
				if view then
					vim.cmd("DiffviewClose")
				else
					vim.cmd("DiffviewFileHistory %")
				end
      end,
      "Git file history"
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

return M

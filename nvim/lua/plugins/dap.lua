return {
	{
		"rcarriga/nvim-dap-ui",
		-- lazy = false,
		dependencies = { "mfussenegger/nvim-dap" },
		keys = {
			{
				"<leader>du",
				function()
					require("dapui").toggle()
				end,
				"Toggle dap ui",
			},
		},
		init = function()
			require("neodev").setup({
				library = { plugins = { "nvim-dap-ui" }, types = true },
			})

			vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "@error", linehl = "", numhl = "" })
		end,
		opts = {
			icons = { expanded = "", collapsed = "", current_frame = "" },
			floating = {
				border = "single",
			},
		},
	},
}

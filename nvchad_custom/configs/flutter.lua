local M = {}

M.setup = function()
	require("flutter-tools").setup({
		lsp = {
			color = {
				enabled = true,
				background = false,
				foreground = false,
				virtual_text = true,
				virtual_text_str = "■",
			},
		},
		debugger = {
			enabled = true,
			run_via_dap = true,
			exception_breakpoints = {},
			register_configurations = function(_)
				require("dap").configurations.dart = {}
				require("dap.ext.vscode").load_launchjs()
			end,
		},
		dev_log = {
			enabled = false,
		},
	})
	require("telescope").load_extension("flutter")
end

return M

local M = {}

-- local on_attach = require("custom.configs.overrides").on_attach
local on_attach = require("plugins.configs.lspconfig").on_attach

M.setup = function()
	require("flutter-tools").setup({
		lsp = {
			on_attach = on_attach,
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

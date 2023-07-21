local present, flutter_tools = pcall(require, "flutter-tools")

if not present then
	return
end

require("telescope").load_extension("flutter")

flutter_tools.setup({
	lsp = {
		on_attach = function(client, bufnr)
			require("custom.configs.lspconfig").on_attach_format(client, bufnr)
			require("custom.configs.lspconfig").on_attach(client, bufnr)
		end,
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

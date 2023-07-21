	require("telescope").load_extension("flutter")
	require("flutter-tools").setup({
		lsp = {
			capabilities = vim.lsp.protocol.make_client_capabilities(),
			on_attach = function(client, bufnr)
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

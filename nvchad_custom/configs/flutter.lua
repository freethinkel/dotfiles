local present, flutter_tools = pcall(require, "flutter-tools")

if not present then
	return
end

flutter_tools.setup({
	lsp = {
		on_attach = require("lvim.lsp").common_on_attach,
	},
	debugger = { -- integrate with nvim dap + install dart code debugger
		enabled = true,
		exception_breakpoints = {},
		register_configurations = function(_)
			require("dap").configurations.dart = {}
			require("dap.ext.vscode").load_launchjs()
		end,
	},
})

local rt = require("rust-tools")

local capabilities = require("plugins.configs.lspconfig").capabilities
local on_attach = require("custom.configs.overrides").on_attach

rt.setup({
	server = {
		standalone = true,
		capabilities = capabilities,
		on_attach = function(client, bufnr)
			on_attach(client, bufnr)
			vim.keymap.set("n", "K", rt.hover_actions.hover_actions, { buffer = bufnr })
			vim.keymap.set("n", "<leader>la", rt.code_action_group.code_action_group, { buffer = bufnr })
		end,
	},
})

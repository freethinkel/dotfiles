local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = require("lspconfig")
local servers = { "html", "cssls", "clangd", "svelte", "eslint", "tsserver", "dartls", "rust_analyzer", "prismals" }

for _, lsp in ipairs(servers) do
	if lsp == "tsserver" or lsp == "eslint" then
		lspconfig[lsp].setup({
			on_attach = on_attach,
			capabilities = capabilities,
			root_dir = require("lspconfig").util.root_pattern(".git", "package.json"),
		})
	else
		lspconfig[lsp].setup({
			on_attach = on_attach,
			capabilities = capabilities,
		})
	end
end

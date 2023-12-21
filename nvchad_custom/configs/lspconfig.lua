local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = require("lspconfig")

local on_attach = require("custom.configs.overrides").on_attach

-- local on_attach = function(client, bufnr)
-- 	local documentFormattingProvider = client.server_capabilities.documentFormattingProvider
-- 	local documentRangeFormattingProvider = client.server_capabilities.documentRangeFormattingProvider
--
-- 	_on_attach(client, bufnr)
--
-- 	client.server_capabilities.documentFormattingProvider = documentFormattingProvider
-- 	client.server_capabilities.documentRangeFormattingProvider = documentRangeFormattingProvider
-- end

-- if you just want default config for the servers then put them in a table
local servers = {
	"html",
	"cssls",
	"tsserver",
	"clangd",
	"eslint",
	"svelte",
	"emmet_ls",
	"cssmodules_ls",
	-- "angularls",
	"grammarly",
}

for _, lsp in ipairs(servers) do
	lspconfig[lsp].setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

lspconfig["stylelint_lsp"].setup({
	on_attach = on_attach,
	capabilities = capabilities,
	filetypes = { "css", "scss", "sass", "pcss", "postcss" },
})

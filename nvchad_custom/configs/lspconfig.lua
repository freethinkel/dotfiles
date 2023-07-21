local M = {}
local on_attach_core = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = require("lspconfig")

-- if you just want default config for the servers then put them in a table
local servers = { "html", "cssls", "tsserver", "clangd", "eslint" }

M.on_attach = function(client, bufnr)
	print(client.server_capabilities.documentFormattingProvider)
	if
		client.server_capabilities.documentFormattingProvider
		or client.server_capabilities.documentRangeFormattingProvider
	then
		vim.api.nvim_create_autocmd("BufWritePre", {
			desc = "Auto format before save",
			callback = function()
				vim.lsp.buf.format()
			end,
		})
	end
	on_attach_core(client, bufnr)
end

for _, lsp in ipairs(servers) do
	lspconfig[lsp].setup({
		on_attach = M.on_attach,
		capabilities = capabilities,
	})
end

return M

--
-- lspconfig.pyright.setup { blabla}

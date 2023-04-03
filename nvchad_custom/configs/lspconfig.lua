local M = {}

local lsps = {
	"lua_ls",
	"tsserver",
	"eslint",
	"jsonls",
	"emmet_ls",

	-- web dev stuff
	"cssls",
	"html",
	"denols",
}

local formatters = { "prettier", "stylua" }

M.on_attach = function(client, bufnr)
	local allowFormat = client.server_capabilities.documentFormattingProvider
	if allowFormat then
		vim.api.nvim_create_autocmd("BufWritePre", {
			desc = "Auto format before save",
			callback = function()
				vim.lsp.buf.format()
			end,
		})
	end
	require("plugins.configs.lspconfig").on_attach(client, bufnr)
	client.server_capabilities.documentFormattingProvider = allowFormat
end

M.setup = function()
	require("plugins.configs.lspconfig")

	local capabilities = require("plugins.configs.lspconfig").capabilities

	require("mason").setup()
	require("mason-lspconfig").setup({
		ensure_installed = lsps,
	})

	local servers = require("mason-lspconfig").get_installed_servers()

	local lspconfig = require("lspconfig")

	for _, server in pairs(servers) do
		lspconfig[server].setup({
			on_attach = M.on_attach,
			capabilities = capabilities,
		})
	end
end

M.null_ls = function()
	require("mason").setup()
	require("mason-null-ls").setup({
		automatic_setup = true,
		ensure_installed = formatters,
	})
	require("null-ls").setup()
	require("mason-null-ls").setup_handlers()
end

M.lspsaga = function()
	require("lspsaga").setup({
		ui = {
			code_action = "",
			title = true,
			border = "single",
			winblend = 0,
			expand = "",
			collapse = "",
			incoming = " ",
			outgoing = " ",
			hover = " ",
			kind = {},
		},
	})
end

return M

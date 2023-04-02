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

local formatters = {
	"prettier",
	"stylua",
}

M.setup = function()
	require("plugins.configs.lspconfig")

	local on_attach = function(client, bufnr)
		if client.server_capabilities.documentFormattingProvider then
			vim.api.nvim_create_autocmd("BufWritePre", {
				desc = "Auto format before save",
				pattern = "<buffer>",
				callback = function()
					vim.lsp.buf.format()
				end,
			})
		end
		require("plugins.configs.lspconfig").on_attach(client, bufnr)
	end
	local capabilities = require("plugins.configs.lspconfig").capabilities

	require("mason").setup()
	require("mason-lspconfig").setup({
		ensure_installed = lsps,
	})

	local servers = require("mason-lspconfig").get_installed_servers()

	local lspconfig = require("lspconfig")

	for _, server in pairs(servers) do
		lspconfig[server].setup({
			on_attach = on_attach,
			capabilities = capabilities,
		})
	end
end

M.null_ls = function()
	require("mason-null-ls").setup({
		automatic_setup = true,
		ensure_installed = formatters,
	})
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

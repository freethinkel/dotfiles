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
}

local formatters = { "prettier", "stylua" }

M.on_attach_format = function(client, bufnr)
	if client.server_capabilities.documentFormattingProvider then
		vim.api.nvim_create_autocmd("BufWritePre", {
			desc = "Auto format before save",
			callback = function()
				vim.lsp.buf.format({
					timeout = 1000,
					bufnr = bufnr,
					filter = function(cl)
						return cl.name == "null-ls"
					end,
				})
			end,
		})
	end
end

M.on_attach = function(client, bufnr)
	require("plugins.configs.lspconfig").on_attach(client, bufnr)
end

M.setup = function()
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
	require("plugins.configs.lspconfig")
end

M.null_ls = function()
	require("mason").setup()
	require("mason-null-ls").setup({
		automatic_setup = true,
		ensure_installed = formatters,
	})
	local null_ls = require("null-ls")
	null_ls.setup({
		on_attach = M.on_attach_format,
		sources = {
			require("custom.utils").merge_tb(null_ls.builtins.formatting.prettier, { filetypes = { "postcss" } }),
		},
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

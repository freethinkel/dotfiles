local M = {}

M.on_attach = function(client, bufnr)
	if client.server_capabilities.documentFormattingProvider then
		vim.api.nvim_command("augroup Format")
		vim.api.nvim_command("autocmd! * <buffer>")
		vim.api.nvim_command(
			"autocmd "
				.. (vim.bo.filetype == "prisma" and "BufWritePost" or "BufWritePre")
				.. " <buffer> lua vim.lsp.buf.formatting_seq_sync(nil, 2000, {'null-ls'})"
		)
		vim.api.nvim_command("autocmd BufWritePost <buffer> lua vim.lsp.buf.formatting_seq_sync()")
		vim.api.nvim_command("augroup END")
	end
end

M.capabilities = vim.lsp.protocol.make_client_capabilities()

M.capabilities.textDocument.completion.completionItem = {
	documentationFormat = { "markdown", "plaintext" },
	snippetSupport = true,
	preselectSupport = true,
	insertReplaceSupport = true,
	labelDetailsSupport = true,
	deprecatedSupport = true,
	commitCharactersSupport = true,
	tagSupport = { valueSet = { 1 } },
	resolveSupport = {
		properties = {
			"documentation",
			"detail",
			"additionalTextEdits",
		},
	},
}

M.setup = function()
	local status, lspconfig = pcall(require, "lspconfig")
	if not status then
		return
	end

	local servers = require("core.utils").load_config().lsp.servers or {}

	for _, lsp in ipairs(servers) do
		lspconfig[lsp].setup({
			on_attach = M.on_attach,
			capabilities = M.capabilities,
		})
	end

	lspconfig.sumneko_lua.setup({
		on_attach = M.on_attach,
		capabilities = M.capabilities,

		settings = {
			Lua = {
				diagnostics = {
					globals = { "vim" },
				},
				workspace = {
					library = {
						[vim.fn.expand("$VIMRUNTIME/lua")] = true,
						[vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
					},
					maxPreload = 100000,
					preloadFileSize = 10000,
				},
			},
		},
	})
end

return M

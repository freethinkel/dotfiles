local null_ls = require("null-ls")
local b = null_ls.builtins

local prettier_format_filetypes = {
	"html",
	"markdown",
	"css",
	"typescript",
	"javascript",
	"typescriptreact",
	"javascriptreact",
	"svelte",
	"postcss",
	"json",
}

local sources = {
	b.formatting.prettier.with({
		filetypes = prettier_format_filetypes,
	}),
	b.formatting.dart_format,
	-- Prisma
	b.formatting.prismaFmt,
	-- Lua
	b.formatting.stylua,
	b.diagnostics.luacheck.with({ extra_args = { "--global vim" } }),

	-- Shell
	b.formatting.shfmt,
	-- b.diagnostics.shellcheck.with({ diagnostics_format = "#{m} [#{c}]" }),
}

local M = {}

_G.prismaFormat = function()
	vim.lsp.buf.formatting_seq_sync(nil, 2000, { "null-ls" })
	vim.cmd("noautocmd write")
end

_G.eslintFixAll = function()
	vim.cmd(":EslintFixAll")
end

local on_attach = function(client)
	-- vim.pretty_print(client.server_capabilities)
	if client.server_capabilities.documentFormattingProvider then
		if vim.bo.filetype == "prisma" then
			vim.cmd("autocmd BufWritePost <buffer> lua prismaFormat()")
		else
			-- vim.cmd("autocmd BufWritePre <buffer> lua pcall(eslintFixAll)")
			vim.cmd("autocmd BufWritePre <buffer> lua vim.lsp.buf.format({timeout_ms = 2000})")
		end
	end
end

M.setup = function()
	null_ls.setup({
		debug = true,
		sources = sources,

		-- format on save
		on_attach = on_attach,
	})
end

return M

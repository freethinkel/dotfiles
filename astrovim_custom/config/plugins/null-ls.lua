local M = {}

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

M.setup = function(config)
	local null_ls = require("null-ls")
	local b = null_ls.builtins

	config.sources = {
		-- Set a formatter that is manually installed
		b.formatting.prettier.with({
			filetypes = prettier_format_filetypes,
		}),
		b.diagnostics.eslint,
		b.formatting.eslint,
		b.formatting.dart_format,
		-- Prisma
		b.formatting.prismaFmt,
		-- Lua
		b.formatting.stylua,
		b.diagnostics.luacheck.with({ extra_args = { "--global vim" } }),

		-- Shell
		b.formatting.shfmt,
		-- Spell
		b.completion.spell,
	}

	return config
end

return M

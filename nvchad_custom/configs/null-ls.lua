local null_ls = require("null-ls")

local b = null_ls.builtins

local sources = {

	-- webdev stuff
	-- b.formatting.deno_fmt, -- choosed deno for ts/js files cuz its very fast!
	b.formatting.prettier.with({
		filetypes = {
			"html",
			"markdown",
			"css",
			"astro",
			"typescript",
			"javascript",
			"postcss",
			"javascriptreact",
			"typescriptreact",
		},
	}), -- so prettier works only on these filetypes
	b.formatting.dart_format,
	-- Lua
	b.formatting.stylua,

	-- cpp
	b.formatting.clang_format,
}

null_ls.setup({
	debug = true,
	sources = sources,
	on_attach = require("custom.configs.overrides").lsp_on_attach,
})

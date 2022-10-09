local M = {
	ui = {
		theme = "tokyonight-storm",
		-- theme = "github_dimmed",
		-- theme = "everblush",
		-- theme = "nord",
	},
	lsp = {
		servers = {
			"html",
			"cssls",
			"clangd",
			"svelte",
			"eslint",
			"tsserver",
			"dartls",
			"rust_analyzer",
			"prismals",
		},
		mason_install = {
			"angular-language-server",
			"luacheck",
			"luaformatter",
			"dockerfile-language-server",
			"css-lsp",
			"stylua",
			"emmet-ls",
			"bash-language-server",
			"cssmodules-language-server",
			"eslint-lsp",
			"json-lsp",
			"lua-language-server",
			"prettier",
			"prisma-language-server",
			"svelte-language-server",
			"typescript-language-server",
			"shellcheck",
			"html-lsp",
		},
	},
}

-- require("config.theme").setup()

return M

local M = {}

-- local _on_attach = require("plugins.configs.lspconfig").on_attach
-- M.on_attach = function(client, bufnr)
-- 	_on_attach(client, bufnr)
-- 	-- local documentFormattingProvider = client.server_capabilities.documentFormattingProvider
-- 	-- local documentRangeFormattingProvider = client.server_capabilities.documentRangeFormattingProvider
-- 	--
-- 	-- _on_attach(client, bufnr)
-- 	--
-- 	-- client.server_capabilities.documentFormattingProvider = documentFormattingProvider
-- 	-- client.server_capabilities.documentRangeFormattingProvider = documentRangeFormattingProvider
-- end

M.treesitter = {
	ensure_installed = {
		"vim",
		"lua",
		"html",
		"css",
		"javascript",
		"typescript",
		"tsx",
		"c",
		"markdown",
		"markdown_inline",
	},
	highlight = {
		enable = true,
	},
	auto_install = true,
	autotag = {
		enable = true,
	},
	indent = { enable = false, disable = { "yaml", "python", "dart" } },
}

M.mason = {
	ensure_installed = {
		-- lua stuff
		"lua-language-server",
		"stylua",

		-- web dev stuff
		"css-lsp",
		"html-lsp",
		"typescript-language-server",
		"deno",
		"prettier",
		"eslint-lsp",
		"stylelint-lsp",
		"cssmodules-language-server",
		"emmet-ls",

		-- c/cpp stuff
		"clangd",
		"clang-format",
	},
}

M.gitsigns = {
	signs = {
		add = { hl = "GitSignsAddLn", text = "▍", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
		change = { hl = "GitSignsChange", text = "▍", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
		delete = { hl = "GitSignsDelete", text = "󰐊", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
		topdelete = { hl = "GitSignsDelete", text = "󰐊", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
		changedelete = { hl = "GitSignsChange", text = "▍", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
		untracked = { hl = "GitSignsAdd", text = "▍", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
	},
	current_line_blame = true,
}

return M

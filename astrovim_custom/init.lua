local M = {
	mappings = require("user.config.mappings"),
	colorscheme = "catppuccin-mocha",
	icons = {
		VimIcon = "",
	},
	heirline = require("user.config.plugins.heirline").config,
	plugins = {
		init = {
			-- THEMES
			["catppuccin/nvim"] = {},
			["projekt0n/github-nvim-theme"] = {},
			-- PLUGINS
			["jxnblk/vim-mdx-js"] = {},
			["stephenway/postcss.vim"] = {},
			["mg979/vim-visual-multi"] = {},
			["folke/zen-mode.nvim"] = {
				config = require("user.config.plugins.zen-mode").setup,
			},
			["mattn/emmet-vim"] = {},
			["dcampos/cmp-emmet-vim"] = {},
		},
		["gitsigns"] = require("user.config.plugins.gitsigns").setup,
		["null-ls"] = require("user.config.plugins.null-ls").setup,
		["heirline"] = require("user.config.plugins.heirline").setup,
		["cmp"] = require("user.config.plugins.cmp").setup,
		["mason-lspconfig"] = {},
	},
	lsp = {
		servers = {
			"tsserver",
		},
		formatting = {
			format_on_save = {
				enabled = true, -- enable or disable format on save globally
			},
			timeout_ms = 2000, -- default format timeout
		},
	},
	header = {
		"  ┌───┐",
		"  │▐█▌│",
		"  │+ ⠔│",
		"  └───'",
		"─────────",
	},
	options = require("user.config.options"),
}

vim.cmd("au BufNewFile,BufRead *.pcss set ft=postcss")
vim.cmd("au BufNewFile,BufRead *.mdx set ft=mdx")

return M

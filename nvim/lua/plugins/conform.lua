return {
	{ -- Autoformat
		"stevearc/conform.nvim",
		opts = {
			notify_on_error = false,
			format_on_save = {
				timeout_ms = 500,
				lsp_fallback = true,
			},
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				sass = { "prettier" },
				pcss = { "prettier" },
				html = { "prettier" },
				json = { "prettier" },
				javascriptreact = { "prettier" },
				svelte = { "svelte" }, -- auto format with lsp
				svg = { "prettier" },
			},
		},
	},
}

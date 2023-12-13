require("conform").setup({
	format_on_save = {
		timeout_ms = 500,
		lsp_fallback = true,
		quiet = true,
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
		svelte = { "prettier" }, -- auto format with lsp
	},
	formatters = {
		injected = { options = { ignore_errors = true } },
	},
})

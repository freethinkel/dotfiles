local capabilities = require("plugins.configs.lspconfig").capabilities
local on_attach = require("plugins.configs.lspconfig").on_attach

local lspconfig = require("lspconfig")

-- if you just want default config for the servers then put them in a table
local servers = {
	"html",
	"cssls",
	"tsserver",
	"clangd",
	"eslint",
	"emmet_ls",
	"cssmodules_ls",
	"autotools_ls",
	"jsonls",
	"astro",
	-- "angularls",
	-- "grammarly",
}

for _, lsp in ipairs(servers) do
	lspconfig[lsp].setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

lspconfig["svelte"].setup({
	on_attach = function(client, bufnr)
		on_attach(client, bufnr)
		vim.api.nvim_create_autocmd("BufWritePost", {
			pattern = { "*.js", "*.ts" },
			callback = function(ctx)
				client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
			end,
		})
	end,
})

lspconfig["stylelint_lsp"].setup({
	on_attach = on_attach,
	capabilities = capabilities,
	filetypes = { "css", "scss", "sass", "pcss", "postcss" },
})

lspconfig.sourcekit.setup({
	capabilities = capabilities,
	on_attach = function(arg1, arg2)
		vim.keymap.set("n", "<leader>dp", require("xbase.pickers.builtin").actions, { desc = "XBase picker" })
		vim.keymap.set("n", "<leader>dl", function()
			require("xbase.logger").toggle(false, true)
		end, { desc = "XBase logger" })
		return on_attach(arg1, arg2)
	end,
	filetypes = { "swift" },
	root_dir = lspconfig.util.root_pattern(
		"*.xcodeproj",
		"*.xcworkspace",
		"Package.swift",
		".git",
		"project.yml",
		"Project.swift"
	),
	cmd = {
		"xcrun",
		"sourcekit-lsp",
		"--log-level",
		"debug",
	},
})

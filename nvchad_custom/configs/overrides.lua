local M = {}

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
M.lsp_on_attach = function(client, bufnr)
	local on_attach = require("plugins.configs.lspconfig").on_attach

	local documentFormattingProvider = client.server_capabilities.documentFormattingProvider
	local documentRangeFormattingProvider = client.server_capabilities.documentRangeFormattingProvider
	on_attach(client, bufnr)
	client.server_capabilities.documentFormattingProvider = documentFormattingProvider
	client.server_capabilities.documentRangeFormattingProvider = documentRangeFormattingProvider

	vim.api.nvim_create_autocmd("FileType", {
		pattern = "qf",
		command = [[nnoremap <buffer> <CR> <CR>:cclose<CR>]],
	})

	if client.server_capabilities.documentFormattingProvider then
		vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = augroup,
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.format()
			end,
		})
	end
end

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
	auto_install = true,
	indent = {
		enable = true,
		disable = { "dart" },
	},
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
-- git support in nvimtree
M.nvimtree = {
	git = {
		enable = true,
	},
	on_attach = function(bufnr)
		local api = require("nvim-tree.api")

		local function opts(desc)
			return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
		end

		local useful_keys = {
			["l"] = { api.node.open.edit, opts("Open") },
			["o"] = { api.node.open.edit, opts("Open") },
			["<CR>"] = { api.node.open.edit, opts("Open") },
			["v"] = { api.node.open.vertical, opts("Open: Vertical Split") },
			["h"] = { api.node.navigate.parent_close, opts("Close Directory") },
			["C"] = { api.tree.change_root_to_node, opts("CD") },
		}
		api.config.mappings.default_on_attach(bufnr)

		for keybind, mapping_info in pairs(useful_keys) do
			vim.keymap.set("n", keybind, mapping_info[1], mapping_info[2])
		end
	end,
	renderer = {
		highlight_git = true,
		icons = {
			show = {
				git = false,
			},
		},
	},
}

return M

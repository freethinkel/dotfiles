local M = {}

-- local lspkind_icons = {
-- 	Text = " ",
-- 	Method = " ",
-- 	Function = " ",
-- 	Constructor = " ",
-- 	Field = " ",
-- 	Variable = " ",
-- 	Class = " ",
-- 	Interface = " ",
-- 	Property = " ",
-- 	Keyword = " ",
-- 	Snippet = " ",
-- 	Color = " ",
-- 	File = " ",
-- 	Reference = " ",
-- 	Folder = " ",
-- 	Struct = " ",
-- 	Event = " ",
-- 	Operator = " ",
-- 	TypeParameter = " ",
-- 	Namespace = "",
-- 	Module = " ",
-- 	Unit = "塞 ",
-- 	Value = " ",
-- 	Enum = " ",
-- 	EnumMember = " ",
-- 	Constant = " ",
-- 	Table = "",
-- 	Object = " ",
-- 	Tag = "",
-- 	Array = "[]",
-- 	Boolean = " ",
-- 	Number = " ",
-- 	Null = "ﳠ",
-- 	String = " ",
-- 	Calendar = "",
-- 	Watch = " ",
-- 	Package = "",
-- 	Copilot = " ",
-- }

M.lspsaga = function()
	local status, lspsaga = pcall(require, "lspsaga")
	if not status then
		return
	end

	lspsaga.setup({
		code_action_icon = "",
		-- code_action_icon = require("custom.modules.nonicons.icons").get("light-bulb"),
	})
end

M.cmp = function()
	return {
		-- formatting = {
		-- 	format = function(_, vim_item)
		-- 		local icons = lspkind_icons
		-- 		vim_item.kind = string.format("%s %s", icons[vim_item.kind], "(" .. string.lower(vim_item.kind) .. ")")
		-- 		return vim_item
		-- 	end,
		-- },
	}
end

M.config = function()
	local on_attach = require("plugins.configs.lspconfig").on_attach
	local capabilities = require("plugins.configs.lspconfig").capabilities

	local lspconfig = require("lspconfig")
	local servers =
		{ "html", "cssls", "clangd", "svelte", "eslint", "tsserver", "deno", "dartls", "rust_analyzer", "prismals" }

	for _, lsp in ipairs(servers) do
		if lsp == "tsserver" or lsp == "eslint" then
			lspconfig[lsp].setup({
				on_attach = on_attach,
				capabilities = capabilities,
				root_dir = require("lspconfig").util.root_pattern(".git", "package.json"),
			})
		else
			if lsp == "deno" then
			-- lspconfig[lsp].setup({
			-- 	on_attach = on_attach,
			-- 	capabilities = capabilities,
			-- 	root_dir = require("lspconfig").util.root_pattern("deno.json"),
			-- })
			else
				lspconfig[lsp].setup({
					on_attach = on_attach,
					capabilities = capabilities,
				})
			end
		end
	end
	require("custom.modules.nonicons.extensions").lsp_hl_override()
end

return M

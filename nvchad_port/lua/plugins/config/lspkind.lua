local kind_presets = {
	default = {
		Text = " ",
		Method = " ",
		Function = " ",
		Constructor = "⌘ ",
		Field = "ﰠ",
		Variable = " ",
		Class = "ﴯ",
		Interface = " ",
		Module = " ",
		Property = "ﰠ",
		Unit = "塞 ",
		Value = " ",
		Enum = " ",
		Keyword = "廓 ",
		Snippet = " ",
		Color = " ",
		File = " ",
		Reference = " ",
		Folder = " ",
		EnumMember = " ",
		Constant = " ",
		Struct = "פּ",
		Event = " ",
		Operator = " ",
		TypeParameter = "",
	},
}

local kind_order = {
	"Text",
	"Method",
	"Function",
	"Constructor",
	"Field",
	"Variable",
	"Class",
	"Interface",
	"Module",
	"Property",
	"Unit",
	"Value",
	"Enum",
	"Keyword",
	"Snippet",
	"Color",
	"File",
	"Reference",
	"Folder",
	"EnumMember",
	"Constant",
	"Struct",
	"Event",
	"Operator",
	"TypeParameter",
}

local M = {}

M.setup = function()
	local status, lspkind = pcall(require, "lspkind")
	if not status then
		return
	end

	lspkind.init({
		-- DEPRECATED (use mode instead): enables text annotations
		--
		-- default: true
		-- with_text = true,

		-- defines how annotations are shown
		-- default: symbol
		-- options: 'text', 'text_symbol', 'symbol_text', 'symbol'
		mode = "symbol_text",

		-- default symbol map
		-- can be either 'default' (requires nerd-fonts font) or
		-- 'codicons' for codicon preset (requires vscode-codicons font)
		--
		-- default: 'default'
		preset = "codicons",

		-- override preset symbols
		-- default: {}
		symbol_map = {
			Text = "",
			Method = "",
			Function = "",
			Constructor = "",
			Field = "ﰠ",
			Variable = "",
			Class = "ﴯ",
			Interface = "",
			Module = "",
			Property = "ﰠ",
			Unit = "塞",
			Value = "",
			Enum = "",
			Keyword = "",
			Snippet = "",
			Color = "",
			File = "",
			Reference = "",
			Folder = "",
			EnumMember = "",
			Constant = "",
			Struct = "פּ",
			Event = "",
			Operator = "",
			TypeParameter = "",
		},
	})
end

M.cmp_format = function(opts)
	local lspkind = require("lspkind")

	if opts == nil then
		opts = {}
	end
	if opts.preset or opts.symbol_map then
		lspkind.init(opts)
	end

	return function(entry, vim_item)
		vim_item.kind = lspkind.symbolic(vim_item.kind, opts)

		if opts.menu ~= nil then
			vim_item.menu = opts.menu[entry.source.name]
		end

		if opts.maxwidth ~= nil then
			vim_item.abbr = string.sub(vim_item.abbr, 1, opts.maxwidth)
		end

		return vim_item
	end
end

return M

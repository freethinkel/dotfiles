local get = require("custom.modules.nonicons.icons").get

local M = {}

M.nvimtree_glyphs = {
	default = get("file"),
	symlink = get("file-symlink-file"),
	folder = {
		default = get("file-directory-fill"),
		open = get("file-directory-open-fill"),
		symlink = get("file-directory-fill"),
		symlink_open = get("file-directory-open-fill"),
		empty = get("file-directory-open-fill"),
		empty_open = get("file-directory-open-fill"),
		arrow_open = get("chevron-down"),
		arrow_closed = get("chevron-right"),
	},
}

M.lsp_hl_override = function ()
	local function lspSymbol(name, icon)
		local hl = "DiagnosticSign" .. name
		vim.fn.sign_define(hl, { text = icon, numhl = hl, texthl = hl })
	end

	lspSymbol("Error", get("stop"))
	lspSymbol("Info", get("info"))
	lspSymbol("Hint", get("light-bulb"))
	lspSymbol("Warn", get("alert"))
end

return M

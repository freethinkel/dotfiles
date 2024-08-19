lvim.keys.insert_mode["jk"] = "<Esc>"
lvim.keys.insert_mode["jj"] = "<Esc>"
lvim.keys.insert_mode["kj"] = "<Esc>"

lvim.builtin.which_key.mappings["l"]["a"] = nil
lvim.builtin.which_key.mappings["c"] = {}
lvim.builtin.which_key.mappings["c"]["a"] = {
	function()
		vim.lsp.buf.code_action()
	end,
	"Code actions",
}

lvim.keys.normal_mode["[d"] = vim.diagnostic.goto_prev
lvim.keys.normal_mode["]d"] = vim.diagnostic.goto_next
-- === !==

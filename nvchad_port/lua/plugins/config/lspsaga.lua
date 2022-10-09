local M = {}

M.setup = function()
	local status, lspsaga = pcall(require, "lspsaga")
	if not status then
		return
	end

	lspsaga.init_lsp_saga({
		border_style = "rounded",
		finder_action_keys = {
			open = "<cr>",
			vsplit = "v",
			split = "s",
			tabe = "t",
			quit = "<ESC>",
			scroll_down = "<C-f>",
			scroll_up = "<C-b>", -- quit can be a table
		},
		code_action_icon = " ", --  
		code_action_keys = {
			quit = "<ESC>",
			exec = "<CR>",
		},
	})
end

return M

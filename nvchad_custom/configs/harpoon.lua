local M = {}

M.setup = function()
	require("harpoon").setup({
		global_settings = {
			save_on_toggle = false,
			save_on_change = true,
			enter_on_sendcmd = false,
			tmux_autoclose_windows = false,
			excluded_filetypes = { "harpoon" },
			mark_branch = false,
			tabline = false,
			tabline_prefix = "   ",
			tabline_suffix = "   ",
		},
	})
	-- vim.cmd("highlight! HarpoonInactive guibg=NONE guifg=#63698c")
	-- vim.cmd("highlight! HarpoonActive guibg=NONE guifg=white")
	-- vim.cmd("highlight! HarpoonNumberActive guibg=NONE guifg=#7aa2f7")
	-- vim.cmd("highlight! HarpoonNumberInactive guibg=NONE guifg=#7aa2f7")
	-- vim.cmd("highlight! TabLineFill guibg=NONE guifg=white")
	require("telescope").load_extension("harpoon")
end

return M

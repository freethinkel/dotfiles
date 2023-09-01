local M = {}

M.setup = function()
	require("neodev").setup({
		library = { plugins = { "nvim-dap-ui" }, types = true },
	})
	require("dapui").setup({
		icons = { expanded = "", collapsed = "", current_frame = "" },
		controls = {
			icons = {
				pause = " ",
				play = "契",
				step_into = " ",
				step_over = " ",
				step_out = " ",
				step_back = " ",
				run_last = " ",
				terminate = " ",
			},
		},
		floating = {
			border = "single",
		},
	})

	require("core.utils").load_mappings("dap")
end

return M

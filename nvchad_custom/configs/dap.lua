local M = {}

M.setup = function()
	require("neodev").setup({
		library = { plugins = { "nvim-dap-ui" }, types = true },
	})
	require("dapui").setup({
		icons = { expanded = "", collapsed = "", current_frame = "" },
		floating = {
			border = "single",
		},
	})

	vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "@error", linehl = "", numhl = "" })

	require("core.utils").load_mappings("dap")
end

return M

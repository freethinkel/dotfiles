local M = {}

M.diffview = function()
	require("diffview").setup({
		diff_binaries = false,
		enhanced_diff_hl = true,
		use_icons = true,
		hooks = {
			view_opened = function()
				-- local custom_colors = require("custom.colors")
				require("indent_blankline.commands").disable()
        require("custom.highlights").override_hightlight();
			end,
		},
	})
end

return M

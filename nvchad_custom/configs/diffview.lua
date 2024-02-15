local M = {}

M.setup = function()
	local utils = require("custom.utils")

	require("diffview").setup({
		enhanced_diff_hl = true,
		view = {
			-- Configure the layout and behavior of different types of views.
			-- Available layouts:
			--  'diff1_plain'
			--    |'diff2_horizontal'
			--    |'diff2_vertical'
			--    |'diff3_horizontal'
			--    |'diff3_vertical'
			--    |'diff3_mixed'
			--    |'diff4_mixed'
			-- For more info, see ':h diffview-config-view.x.layout'.
			default = {
				-- Config for changed files, and staged files in diff views.
				layout = "diff2_horizontal",
				winbar_info = true, -- See ':h diffview-config-view.x.winbar_info'
			},
		},
		hooks = {
			view_opened = function(view)
				local function post_layout()
					utils.tbl_ensure(view, "winopts.diff2.a")
					utils.tbl_ensure(view, "winopts.diff2.b")
					view.winopts.diff2.a = utils.tbl_union_extend(view.winopts.diff2.a, {
						winhl = {
							"DiffChange:DiffAddAsDelete",
							"DiffText:DiffDeleteText",
						},
					})
					view.winopts.diff2.b = utils.tbl_union_extend(view.winopts.diff2.b, {
						winhl = {
							"DiffChange:DiffAdd",
							"DiffText:DiffAddText",
						},
					})
				end

				view.emitter:on("post_layout", post_layout)
				post_layout()
			end,
		},
	})
end

return M

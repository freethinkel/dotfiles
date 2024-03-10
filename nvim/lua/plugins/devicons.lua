return {
	{
		"nvim-tree/nvim-web-devicons",
		lazy = false,
		config = function()
			require("nvim-web-devicons").setup({
				strict = true,
				override_by_extension = {
					astro = {
						icon = "",
						color = "#EF8547",
						name = "astro",
					},
					pcss = {
						icon = "",
						color = "#D7380B",
						name = "postcss",
					},
				},
			})
		end,
	},
}

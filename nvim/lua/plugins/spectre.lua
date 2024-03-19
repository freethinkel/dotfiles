return {
	{
		"nvim-pack/nvim-spectre",
		keys = {
			{
				"<leader>sR",
				function()
					require("spectre").open()
				end,
				"Spectre",
			},
		},
		config = function()
			require("spectre").setup()
		end,
	},
}

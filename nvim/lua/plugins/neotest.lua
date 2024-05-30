return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-treesitter/nvim-treesitter",
		"nvim-neotest/neotest-jest",
	},
	config = function()
		require("neotest").setup({
			adapters = {
				require("neotest-jest")({
					jestCommand = "node_modules/.bin/jest",
					jestConfigFile = function(file)
						-- vim.fn.
						if string.find(file, "/apps/") then
							return string.match(file, "(.-/[^/]+/)src") .. "jest.config.js"
						end

						print(vim.fn.getcwd() .. "/jest.config.ts")

						return vim.fn.getcwd() .. "/jest.config.ts"
					end,
					-- env = { CI = true },
					cwd = function(file)
						return vim.fn.getcwd()
					end,
				}),
			},
		})
	end,
}

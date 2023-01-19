return {
	["evanleck/vim-svelte"] = {},
	["jose-elias-alvarez/null-ls.nvim"] = {
		after = "nvim-lspconfig",
		config = function()
			require("custom.plugins.config.null-ls").setup()
		end,
	},
	["jiangmiao/auto-pairs"] = {},
	["christoomey/vim-tmux-navigator"] = {},
	["stephenway/postcss.vim"] = {},
	["thosakwe/vim-flutter"] = {},
	["styled-components/vim-styled-components"] = {},
	["goolord/alpha-nvim"] = {
		disable = false,
		config = function()
			require("custom.plugins.config.alpha")
		end,
	},
	["jxnblk/vim-mdx-js"] = {},
	["projekt0n/github-nvim-theme"] = {},
	["neovim/nvim-lspconfig"] = {
		config = function()
			require("plugins.configs.lspconfig")
			require("custom.plugins.config.lsp").config()
		end,
	},
	["tpope/vim-fugitive"] = {},
	["windwp/nvim-ts-autotag"] = {
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	},
	["folke/which-key.nvim"] = { disable = false },
	["folke/todo-comments.nvim"] = {
		requires = "nvim-lua/plenary.nvim",
		config = function()
			require("custom.plugins.config.todo-comments").setup()
		end,
	},
	["ahmedkhalf/project.nvim"] = {
		after = "telescope.nvim",
		config = function()
			require("custom.plugins.config.telescope").setup()
			require("custom.plugins.config.projects").setup()
		end,
	},
	["mg979/vim-visual-multi"] = {},
	["jwalton512/vim-blade"] = {},
	["nvim-lua/plenary.nvim"] = {},
	["sindrets/diffview.nvim"] = {
		requires = "nvim-lua/plenary.nvim",
		module = "git",
		config = function()
			require("custom.plugins.config.diffview").setup()
		end,
	},
	["chrsm/impulse.nvim"] = {
		requires = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
		config = function()
			require("custom.plugins.config.impulse").setup()
		end,
	},
	["windwp/nvim-spectre"] = {},
	["nvim-telescope/telescope-media-files.nvim"] = {},
	["folke/zen-mode.nvim"] = {
		config = function()
			require("custom.plugins.config.zen-mode").setup()
		end,
	},
	["glepnir/lspsaga.nvim"] = {
		config = function()
			require("custom.plugins.config.lsp").lspsaga()
		end,
	},
	["kyazdani42/nvim-web-devicons"] = {
		-- config = function()
		-- 	require("custom.modules.nonicons").setup()
		-- end,
	},
	-- ["yamatsum/nvim-nonicons"] = {
	-- 	requires = { "kyazdani42/nvim-web-devicons" },
	-- 	config = function()
	-- 		require("nvim-nonicons").setup()
	-- 	end,
	-- },
}

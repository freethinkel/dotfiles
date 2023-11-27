local overrides = require("custom.configs.overrides")

---@type NvPluginSpec[]
local plugins = {
	-- {
	-- 	"yamatsum/nvim-nonicons",
	-- 	dependencies = { "kyazdani42/nvim-web-devicons" },
	-- 	lazy = false,
	-- 	config = function()
	-- 		require("nvim-nonicons").setup({})
	-- 	end,
	-- },
	{
		"nvim-telescope/telescope-media-files.nvim",
		config = function()
			require("telescope").load_extension("media_files")
		end,
	},
	{
		"NvChad/base46",
		lazy = false,
		config = function()
			require("custom.highlights").override_highlights()
			require("base46").load_all_highlights()
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{
				"stevearc/conform.nvim",
				config = function()
					require("custom.configs.conform")
				end,
			},
		},
		config = function()
			require("plugins.configs.lspconfig")
			require("custom.configs.lspconfig")
		end, -- Override to setup mason-lspconfig
	},
	{
		"akinsho/flutter-tools.nvim",
		lazy = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"stevearc/dressing.nvim", -- optional for vim.ui.select
			"nvim-lspconfig",
		},
		config = function()
			require("custom.configs.flutter").setup()
		end,
	},
	{
		"rcarriga/nvim-dap-ui",
		lazy = false,
		dependencies = { "mfussenegger/nvim-dap" },
		config = function()
			require("custom.configs.dap").setup()
		end,
	},
	{
		"williamboman/mason.nvim",
		opts = overrides.mason,
	},

	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"windwp/nvim-ts-autotag",
		},
		opts = overrides.treesitter,
	},
	{
		"folke/neodev.nvim",
		lazy = true,
	},

	{
		"nvim-tree/nvim-tree.lua",
		config = function()
			require("custom.configs.nvimtree")
		end,
	},
	{
		"lewis6991/gitsigns.nvim",
		opts = overrides.gitsigns,
	},
	{
		"kdheepak/lazygit.nvim",
		keys = {
			{ "<leader>gg", "<cmd>LazyGit<cr>", desc = "Toggle lazy git" },
		},
	},
	{ "christoomey/vim-tmux-navigator", lazy = false },
	{
		"max397574/better-escape.nvim",
		event = "InsertEnter",
		config = function()
			require("better_escape").setup()
		end,
	},
	{
		"windwp/nvim-ts-autotag",
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	},
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		event = { "BufReadPre" },
		config = function()
			require("todo-comments").setup()
		end,
	},
	{
		"phaazon/hop.nvim",
		lazy = false,
		config = function()
			require("hop").setup()
		end,
	},
	{
		"nvim-pack/nvim-spectre",
		config = function()
			require("spectre").setup()
		end,
	},
	{
		"mg979/vim-visual-multi",
		lazy = false,
	},
	-- {
	-- 	name = "project-info",
	-- 	dir = "~/Developer/dev/pet/project_info",
	-- 	lazy = false,
	-- 	dev = true,
	-- 	config = function()
	-- 		vim.print(require("project-info"))
	-- 	end,
	-- },
}

return plugins

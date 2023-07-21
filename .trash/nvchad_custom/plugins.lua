local overrides = require("custom.configs.overrides")

---@type NvPluginS()
local plugins = {
	{
		"williamboman/mason.nvim",
		dependencies = { "williamboman/mason-lspconfig.nvim", "neovim/nvim-lspconfig" },
		lazy = false,
		build = ":MasonUpdate",
		config = function()
			require("custom.configs.lspconfig").setup()
		end,
	},
	{
		"jay-babu/mason-null-ls.nvim",
		lazy = false,
		dependencies = {
			"williamboman/mason.nvim",
			"jose-elias-alvarez/null-ls.nvim",
		},
		config = function()
			require("custom.configs.lspconfig").null_ls()
		end,
	},
	{
		"glepnir/lspsaga.nvim",
		lazy = false,
		config = function()
			require("custom.configs.lspconfig").lspsaga()
		end,
		dependencies = {
			{ "nvim-tree/nvim-web-devicons" },
			{ "nvim-treesitter/nvim-treesitter" },
		},
	},
	{
		"nvim-treesitter/nvim-treesitter",
		opts = overrides.treesitter,
	},

	{
		"nvim-tree/nvim-tree.lua",
		opts = overrides.nvimtree,
	},
	{
		"max397574/better-escape.nvim",
		event = "InsertEnter",
		config = function()
			require("better_escape").setup()
		end,
	},
	{ "stephenway/postcss.vim" },

	{
		"akinsho/flutter-tools.nvim",
		lazy = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"stevearc/dressing.nvim",
		},
		config = function()
			require("custom.configs.flutter")
		end,
	},
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "mfussenegger/nvim-dap" },
		config = function()
			require("custom.configs.dap").setup_ui()
		end,
	},
	{
		"lewis6991/gitsigns.nvim",
		opts = overrides.gitsigns,
	},
	{
		"sindrets/diffview.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		lazy = false,
		config = function()
			require("custom.configs.git").diffview()
		end,
	},
	{
		"NvChad/base46",
		lazy = false,
		config = function()
			require("custom.highlights").override_hightlight()
		end,
	},
	{
		"aserowy/tmux.nvim",
		lazy = false,
		config = function()
			require("tmux").setup()
		end,
	},
	{
		"mg979/vim-visual-multi",
		event = "BufEnter",
	},
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		event = { "BufReadPre" },
		config = function()
			require("custom.configs.todo-comments").setup()
		end,
	},
	{
		"imsnif/kdl.vim",
		event = { "BufEnter *.kdl" },
	},
	{
		"stephenway/postcss.vim",
		ft = "postcss",
	},
	{
		"nvim-pack/nvim-spectre",
		config = function()
			require("custom.configs.spectre").setup()
		end,
	},
	{
		"folke/zen-mode.nvim",
		cmd = "ZenMode",
		config = function()
			require("zen-mode").setup({
				window = {
					width = 0.8,
				},
			})
		end,
	},
}

return plugins

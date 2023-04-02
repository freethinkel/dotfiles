local overrides = require("custom.configs.overrides")

---@type NvPluginSpec[]
local plugins = {
	{
		"williamboman/mason.nvim",
		dependencies = { "williamboman/mason-lspconfig.nvim", "neovim/nvim-lspconfig" },
		build = ":MasonUpdate",
		config = function()
			require("custom.configs.lspconfig").setup()
		end,
	},
	{
		"jay-babu/mason-null-ls.nvim",
		event = { "BufReadPre", "BufNewFile" },
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
		event = "LspAttach",
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
		config = function()
			require("custom.configs.flutter")
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
    event = "BufEnter"
  }
	-- {
	-- 	"NvChad/nvim-colorizer.lua",
	-- 	enabled = true,
	-- },
}

return plugins

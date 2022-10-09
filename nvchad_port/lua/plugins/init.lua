vim.cmd("packadd packer.nvim")

local plugins = {
	["nvim-lua/plenary.nvim"] = { module = "plenary" },
	["wbthomason/packer.nvim"] = {
		cmd = require("core.lazy_load").packer_cmds,
		config = function()
			require("plugins")
		end,
	},
	["goolord/alpha-nvim"] = {

		requires = { "kyazdani42/nvim-web-devicons" },
		config = function()
			require("plugins.config.alpha").setup()
		end,
	},
	["folke/which-key.nvim"] = {
		config = function()
			require("plugins.config.which-key").setup()
		end,
	},
	["kyazdani42/nvim-tree.lua"] = {
		requires = {
			"kyazdani42/nvim-web-devicons", -- optional, for file icons
		},
		config = function()
			require("plugins.config.nvim-tree").setup()
		end,
	},
	["nvim-lualine/lualine.nvim"] = {
		requires = { "kyazdani42/nvim-web-devicons", opt = true },
		config = function()
			require("plugins.config.lualine").setup()
		end,
	},
	["neovim/nvim-lspconfig"] = {
		config = function()
			require("plugins.config.lspconfig").setup()
		end,
	},
	["williamboman/mason.nvim"] = {
		config = function()
			require("plugins.config.mason").setup()
		end,
	},
	["glepnir/lspsaga.nvim"] = {
		branch = "main",
		config = function()
			require("plugins.config.lspsaga").setup()
		end,
	},
	["onsails/lspkind-nvim"] = {
		config = function()
			require("plugins.config.lspkind").setup()
		end,
	},
	["hrsh7th/cmp-buffer"] = {},
	["hrsh7th/cmp-nvim-lsp"] = {},
	["hrsh7th/nvim-cmp"] = {
		config = function()
			require("plugins.config.cmp")
		end,
	},
	["jose-elias-alvarez/null-ls.nvim"] = {
		config = function()
			require("plugins.config.null-ls").setup()
		end,
	},
	["L3MON4D3/LuaSnip"] = {
		wants = "friendly-snippets",
		after = "nvim-cmp",
		config = function()
			require("plugins.config.luasnip").setup()
		end,
	},
	["akinsho/bufferline.nvim"] = {
		tag = "v2.*",
		requires = "kyazdani42/nvim-web-devicons",
		config = function()
			require("plugins.config.bufferline").setup()
		end,
	},
	["nvim-treesitter/nvim-treesitter"] = {
		run = ":TSUpdate",
		config = function()
			require("plugins.config.treesitter").setup()
		end,
	},
	["lukas-reineke/indent-blankline.nvim"] = {
		config = function()
			require("plugins.config.blankline").setup()
		end,
	},
	["lewis6991/gitsigns.nvim"] = {
		config = function()
			require("plugins.config.gitsigns").setup()
		end,
	},
	["windwp/nvim-autopairs"] = {
		after = "nvim-cmp",
		config = function()
			require("plugins.config.autopairs").setup()
		end,
	},
	["nvim-telescope/telescope.nvim"] = {
		tag = "0.1.0",
		config = function()
			require("plugins.config.telescope").setup()
		end,
	},
	["ahmedkhalf/project.nvim"] = {
		after = "telescope.nvim",
		config = function()
			require("plugins.config.telescope-project").setup()
		end,
	},
	["sindrets/diffview.nvim"] = {
		requires = "nvim-lua/plenary.nvim",
		config = function()
			require("plugins.config.diffview").setup()
		end,
	},
	["mg979/vim-visual-multi"] = {},
	["simrat39/symbols-outline.nvim"] = {
		config = function()
			require("plugins.config.symbols-outline").setup()
		end,
	},
	["numToStr/Comment.nvim"] = {
		config = function()
			require("plugins.config.comment").setup()
		end,
	},
	["voldikss/vim-floaterm"] = {},
	["christoomey/vim-tmux-navigator"] = {},
	-- THEMES
	["folke/tokyonight.nvim"] = {
		branch = "main",
	},
	["projekt0n/github-nvim-theme"] = {},
	["mangeshrex/everblush.vim"] = {},
	["arcticicestudio/nord-vim"] = {},
}

require("core.packer").run(plugins)

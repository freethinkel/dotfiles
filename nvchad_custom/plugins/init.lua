return {
	["evanleck/vim-svelte"] = {},
	["jose-elias-alvarez/null-ls.nvim"] = {
		after = "nvim-lspconfig",
		config = function()
			require("custom.plugins.null-ls").setup()
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
			require("custom.plugins.alpha")
		end,
	},
	["jxnblk/vim-mdx-js"] = {},
	["projekt0n/github-nvim-theme"] = {},
	["neovim/nvim-lspconfig"] = {
		config = function()
			require("plugins.configs.lspconfig")
			require("custom.plugins.lspconfig")
		end,
	},
	["tpope/vim-fugitive"] = {},
	["windwp/nvim-ts-autotag"] = {
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	},
	["folke/which-key.nvim"] = { disable = false },
	["glepnir/lspsaga.nvim"] = {
		config = function()
			require("custom.plugins.lspsaga").setup()
		end,
	},
	["williamboman/mason.nvim"] = require("custom.plugins.mason"),
}

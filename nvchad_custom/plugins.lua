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
		lazy = false,
		"fladson/vim-kitty",
	},
	{
		"folke/zen-mode.nvim",
		lazy = false,
		config = function()
			require("custom.configs.zen-mode").setup()
		end,
	},
	{
		"nvim-telescope/telescope-media-files.nvim",
		config = function()
			require("telescope").load_extension("media_files")
		end,
	},
	{
		"NvChad/ui",
		config = function()
			-- require("plugins.configs.others").nvchad_ui()
			vim.opt.statusline = ""
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
	{ "JoosepAlviste/nvim-ts-context-commentstring", lazy = false },
	{
		"numToStr/Comment.nvim",
		init = function()
			require("core.utils").load_mappings("comment")
		end,
		dependencies = {
			"JoosepAlviste/nvim-ts-context-commentstring",
		},
		config = function(_, opts)
			require("Comment").setup({
				pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
			})
		end,
	},
	{
		"xbase-lab/xbase",
		ft = "swift",
		build = "make install", -- or "make install && make free_space" (not recommended, longer build time)
		dependencies = {
			"neovim/nvim-lspconfig",
			-- "nvim-telescope/telescope.nvim", -- optional
			-- "nvim-lua/plenary.nvim", -- optional/requirement of telescope.nvim
			-- "stevearc/dressing.nvim", -- optional (in case you don't use telescope but something else)
		},
		config = function()
			require("xbase").setup({
				log_level = vim.log.levels.DEBUG,
				simctl = {
					iOS = {
						"iPhone 15 Pro",
					},
				},
				mappings = {
					build_picker = 0,
					run_picker = 0,
					watch_picker = 0,
					all_picker = 0,
					toggle_split_log_buffer = 0,
					toggle_vsplit_log_buffer = 0,
				},
			}) -- see default configuration bellow
		end,
	},
	{
		"davidmh/cspell.nvim",
		lazy = false,
		enabled = false,
		dependencies = {
			"nvimtools/none-ls.nvim",
		},
		config = function()
			local function split(str, sep)
				local result = {}
				local regex = ("([^%s]+)"):format(sep)
				for each in str:gmatch(regex) do
					table.insert(result, each)
				end
				return result
			end
			local cspell = require("cspell")
			local config = {
				find_json = function(cwd)
					print(cwd)

					return cwd .. "/allowedWords.txt"
					-- return
				end,
				decode_json = function(cspell_str)
					print("decode")
					return split(cspell_str, "\n")
				end,
				encode_json = function(cspell_str)
					print(cspell_str)
					return cspell_str
				end,
			}

			local on_attach = overrides.on_attach

			require("null-ls").setup({
				on_attach = on_attach,
				sources = {
					cspell.diagnostics.with({ config = config }),
					cspell.code_actions.with({ config = config }),
				},
			})
		end,
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
		"simrat39/rust-tools.nvim",
		ft = "rust",
		config = function()
			require("custom.configs.rust")
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
		"nvim-neo-tree/neo-tree.nvim",
		lazy = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
			"3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
		},
		config = function()
			require("custom.configs.neotree").setup()
		end,
	},
	{
		"nvim-tree/nvim-tree.lua",
		enabled = false,
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
	{
		"folke/persistence.nvim",
		event = "BufReadPre",
		opts = {},
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		event = "BufReadPost",
		opts = {
			throttle = true,
			max_lines = 0,
			patterns = {
				default = {
					"class",
					"function",
					"method",
				},
			},
		},
	},
	{
		{
			"Wansmer/treesj",
			keys = { { "<leader>lt", "<CMD>TSJToggle<CR>", desc = "Toggle Treesitter Join" } },
			cmd = { "TSJToggle" },
			opts = { use_default_keymaps = false },
			init = function()
				require("core.mappings").treesj = {
					n = {
						["<leader>lt"] = { "<CMD>TSJToggle<CR>", "Toggle Treesitter Join/Split" },
					},
				}
				require("core.utils").load_mappings("treesj")
			end,
		},
	},
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen" },
		config = function()
			require("custom.configs.diffview").setup()
		end,
	},
	{
		"lukas-reineke/headlines.nvim",
		dependencies = "nvim-treesitter/nvim-treesitter",
		config = true, -- or `opts = {}`
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

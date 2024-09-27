return {
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		enabled = false,
		keys = {
			{ "<leader>e", "<cmd>NvimTreeToggle<cr>", "Toggle explorer" },
		},
		config = function()
			require("nvim-tree").setup({
				git = {
					enable = true,
				},
				filters = {
					git_ignored = false,
					dotfiles = false,
					git_clean = false,
					no_buffer = false,
					custom = {},
					exclude = {},
				},
				hijack_cursor = false,
				auto_reload_on_write = true,
				update_focused_file = {
					enable = true,
				},
				diagnostics = {
					enable = false,
					show_on_dirs = true,
					show_on_open_dirs = true,
					debounce_delay = 50,
					severity = {
						min = vim.diagnostic.severity.HINT,
						max = vim.diagnostic.severity.ERROR,
					},
				},

				filesystem_watchers = {
					enable = true,
					debounce_delay = 100,
				},
				actions = {
					open_file = {
						resize_window = false,
					},
				},
				on_attach = function(bufnr)
					local api = require("nvim-tree.api")

					local function opts(desc)
						return {
							desc = "nvim-tree: " .. desc,
							buffer = bufnr,
							noremap = true,
							silent = true,
							nowait = true,
						}
					end

					local useful_keys = {
						["l"] = { api.node.open.edit, opts("Open") },
						["o"] = { api.node.open.edit, opts("Open") },
						["<CR>"] = { api.node.open.edit, opts("Open") },
						["v"] = { api.node.open.vertical, opts("Open: Vertical Split") },
						["h"] = { api.node.navigate.parent_close, opts("Close Directory") },
						["C"] = { api.tree.change_root_to_node, opts("CD") },
					}
					api.config.mappings.default_on_attach(bufnr)

					for keybind, mapping_info in pairs(useful_keys) do
						vim.keymap.set("n", keybind, mapping_info[1], mapping_info[2])
					end
				end,
				view = {
					signcolumn = "yes",
				},
				renderer = {
					highlight_git = true,
					indent_markers = {
						enable = false,
					},
					indent_width = 2,
					icons = {
						show = {
							git = false,
						},
						glyphs = {
							folder = {
								arrow_closed = "",
								arrow_open = "",
							},
							git = {
								unstaged = "M",
								staged = "S",
								unmerged = "M",
								renamed = "R",
								untracked = "U",
								deleted = "D",
								ignored = "",
							},
						},
						git_placement = "after",
						diagnostics_placement = "signcolumn",
						modified_placement = "after",
					},
				},
			})
		end,
	},
}

local M = {}

M.config = {
	separators = {
		left = { "", " " }, -- separator for the left side of the statusline
		right = { " ", "" }, -- separator for the right side of the statusline
	},
	colors = function(hl)
		hl.blank_bg = astronvim.get_hlgroup("Folded").fg
		hl.file_info_bg = astronvim.get_hlgroup("Visual").bg
		hl.nav_icon_bg = astronvim.get_hlgroup("String").fg
		hl.folder_icon_bg = astronvim.get_hlgroup("Error").fg
		return hl
	end,
}

M.setup = function(config)
	config[1] = {
		hl = { fg = "fg", bg = "bg" },
		astronvim.status.component.mode({
			mode_text = { icon = { kind = "VimIcon", padding = { right = 1, left = 1 } } },
			hl = { fg = "bg" },
			surround = {
				separator = "left",
				color = function()
					return { main = astronvim.status.hl.mode_bg(), right = "blank_bg" }
				end,
			},
		}),
		astronvim.status.component.builder({
			{ provider = "" },
			surround = { separator = "left", color = { main = "blank_bg", right = "file_info_bg" } },
		}),
		astronvim.status.component.file_info({
			file_icon = { highlight = false, padding = { left = 0 } },
			padding = { right = 1 },
			surround = { separator = "left", condition = false },
		}),
		astronvim.status.component.git_branch({ surround = { separator = "none" } }),
		astronvim.status.component.git_diff({ padding = { left = 1 }, surround = { separator = "none" } }),
		astronvim.status.component.fill(),
		astronvim.status.component.lsp({ lsp_client_names = false, surround = { separator = "none", color = "bg" } }),
		astronvim.status.component.fill(),
		astronvim.status.component.diagnostics({ surround = { separator = "right" } }),
		astronvim.status.component.lsp({ lsp_progress = false, surround = { separator = "right" } }),
		{
			astronvim.status.component.builder({
				{ provider = astronvim.get_icon("FolderClosed") },
				padding = { right = 1 },
				hl = { fg = "bg" },
				surround = { separator = "right", color = "folder_icon_bg" },
			}),
			astronvim.status.component.file_info({
				filename = {
					fname = function()
						return vim.fn.getcwd()
					end,
					padding = { left = 1 },
				},
				file_icon = false,
				file_modified = false,
				file_read_only = false,
				surround = { separator = "none", color = "file_info_bg" },
			}),
		},
		{
			astronvim.status.component.builder({
				{ provider = astronvim.get_icon("DefaultFile") },
				padding = { right = 1 },
				hl = { fg = "bg" },
				surround = { separator = "right", color = { main = "nav_icon_bg", left = "file_info_bg" } },
			}),
			astronvim.status.component.nav({
				percentage = { padding = { left = 1, right = 1 } },
				ruler = false,
				scrollbar = false,
				hl = { fg = "nav_icon_bg" },
				surround = { separator = "none", color = "file_info_bg" },
			}),
		},
	}

	return config
end

return M

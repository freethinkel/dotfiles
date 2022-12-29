M = {}

M.diff_add = "#30383E"
M.diff_delete = "#37222C"
M.diff_change = "#333B56"
M.diff_text = "#404D6F"
M.error_unerline = "#d0524c"
M.warn_unerline = "#f29639"

M.hl_add = function()
	return {
		DiffText = {
			fg = "none",
			bg = M.diff_text,
		},
		-- Gitsigns
		GitSignsAdd = {
			fg = "green",
			bg = "none",
		},
		GitSignsChange = {
			fg = "blue",
			bg = "none",
		},
		GitSignsDelete = {
			fg = "red",
			bg = "none",
		},
		GitWordAdd = {
			bg = M.diff_text,
		},
		GitWordDelete = {
			bg = M.diff_text,
		},
		GitSignsAddNr = {
			fg = "green",
			bg = "black",
		},
		GitSignsChangeNr = {
			fg = "blue",
			bg = "black",
		},
		GitSignsDeleteNr = {
			fg = "red",
			bg = "black",
		},
		GitSignsAddLn = {
			fg = "none",
			bg = M.diff_add,
		},
		GitSignsChangeLn = {
			fg = "none",
			bg = M.diff_change,
		},
		GitSignsDeleteLn = {
			fg = "none",
			bg = M.diff_delete,
		},
	}
end

M.hl_override = function()
	return {
		-- Git
		DiffAdd = {
			fg = "none",
			bg = M.diff_add,
		},
		DiffChange = {
			fg = "none",
			bg = M.diff_change,
		},
		DiffDelete = {
			fg = "grey",
			bg = "NONE",
		},
		SignColumn = {
			-- bg = "black",
			bg = "NONE",
		},
		FoldColumn = {
			-- bg = "black",
			bg = "NONE",
		},
	}
end

return M

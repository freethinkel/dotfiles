local fn = vim.fn
local config = require("core.utils").load_config().ui.statusline
local sep_style = config.separator_style

-- ░▒▓█
local separators = { "", "", "", "" }
-- local default_sep_icons = {
-- 	default = { left = "", right = "" },
-- 	round = { left = "", right = "" },
-- 	block = { left = "█", right = "█" },
-- 	arrow = { left = "", right = "" },
-- }

-- 🬀	🬁	🬂	🬃	🬄	🬅	🬆	🬇	🬈	🬉	🬊	🬋	🬌	🬍	🬎	🬏
-- U+1FB1x	🬐	🬑	🬒	🬓	🬔	🬕	🬖	🬗	🬘	🬙	🬚	🬛	🬜	🬝	🬞	🬟
-- U+1FB2x	🬠	🬡	🬢	🬣	🬤	🬥	🬦	🬧	🬨	🬩	🬪	🬫	🬬	🬭	🬮	🬯
-- U+1FB3x	🬰	🬱	🬲	🬳	🬴	🬵	🬶	🬷	🬸	🬹	🬺	🬻	🬼	🬽	🬾	🬿
-- U+1FB4x	🭀	🭁	🭂	🭃	🭄	🭅	🭆	🭇	🭈	🭉	🭊	🭋	🭌	🭍	🭎	🭏
-- U+1FB5x	🭐	🭑	🭒	🭓	🭔	🭕	🭖	🭗	🭘	🭙	🭚	🭛	🭜	🭝	🭞	🭟
-- U+1FB6x	🭠	🭡	🭢	🭣	🭤	🭥	🭦	🭧	🭨	🭩	🭪	🭫	🭬	🭭	🭮	🭯
-- U+1FB7x	🭰	🭱	🭲	🭳	🭴	🭵	🭶	🭷	🭸	🭹	🭺	🭻	🭼	🭽	🭾	🭿
-- U+1FB8x	🮀	🮁	🮂	🮃	🮄	🮅	🮆	🮇	🮈	🮉	🮊	🮋	🮌	🮍	🮎	🮏
-- U+1FB9x	🮐	🮑	🮒		🮔	🮕	🮖	🮗	🮘	🮙	🮚	🮛	🮜	🮝	🮞	🮟
-- U+1FBAx	🮠	🮡	🮢	🮣	🮤	🮥	🮦	🮧	🮨	🮩	🮪	🮫	🮬	🮭	🮮	🮯
-- U+1FBBx	🮰	🮱	🮲	🮳	🮴	🮵	🮶	🮷	🮸	🮹	🮺	🮻	🮼	🮽	🮾	🮿🮜
-- U+1FBCx	🯀	🯁	🯂	🯃	🯄	🯅	🯆	🯇	🯈	🯉	🯊
-- U+1FBDx
-- U+1FBEx
-- U+1FBFx	🯰	🯱	🯲	🯳	🯴	🯵	🯶	🯷	🯸	🯹

-- local separators = se

-- local sep_l = separators["left"]
-- local sep_r = separators["right"]

local function stbufnr()
	return vim.api.nvim_win_get_buf(vim.g.statusline_winid)
end

local function is_activewin()
	return vim.api.nvim_get_current_win() == vim.g.statusline_winid
end

local M = {}

M.modes = {
	["n"] = { "NORMAL", "St_NormalMode" },
	["no"] = { "NORMAL (no)", "St_NormalMode" },
	["nov"] = { "NORMAL (nov)", "St_NormalMode" },
	["noV"] = { "NORMAL (noV)", "St_NormalMode" },
	["noCTRL-V"] = { "NORMAL", "St_NormalMode" },
	["niI"] = { "NORMAL i", "St_NormalMode" },
	["niR"] = { "NORMAL r", "St_NormalMode" },
	["niV"] = { "NORMAL v", "St_NormalMode" },
	["nt"] = { "NTERMINAL", "St_NTerminalMode" },
	["ntT"] = { "NTERMINAL (ntT)", "St_NTerminalMode" },

	["v"] = { "VISUAL", "St_VisualMode" },
	["vs"] = { "V-CHAR (Ctrl O)", "St_VisualMode" },
	["V"] = { "V-LINE", "St_VisualMode" },
	["Vs"] = { "V-LINE", "St_VisualMode" },
	[""] = { "V-BLOCK", "St_VisualMode" },

	["i"] = { "INSERT", "St_InsertMode" },
	["ic"] = { "INSERT (completion)", "St_InsertMode" },
	["ix"] = { "INSERT completion", "St_InsertMode" },

	["t"] = { "TERMINAL", "St_TerminalMode" },

	["R"] = { "REPLACE", "St_ReplaceMode" },
	["Rc"] = { "REPLACE (Rc)", "St_ReplaceMode" },
	["Rx"] = { "REPLACEa (Rx)", "St_ReplaceMode" },
	["Rv"] = { "V-REPLACE", "St_ReplaceMode" },
	["Rvc"] = { "V-REPLACE (Rvc)", "St_ReplaceMode" },
	["Rvx"] = { "V-REPLACE (Rvx)", "St_ReplaceMode" },

	["s"] = { "SELECT", "St_SelectMode" },
	["S"] = { "S-LINE", "St_SelectMode" },
	[""] = { "S-BLOCK", "St_SelectMode" },
	["c"] = { "COMMAND", "St_CommandMode" },
	["cv"] = { "COMMAND", "St_CommandMode" },
	["ce"] = { "COMMAND", "St_CommandMode" },
	["r"] = { "PROMPT", "St_ConfirmMode" },
	["rm"] = { "MORE", "St_ConfirmMode" },
	["r?"] = { "CONFIRM", "St_ConfirmMode" },
	["x"] = { "CONFIRM", "St_ConfirmMode" },
	["!"] = { "SHELL", "St_TerminalMode" },
}

M.mode = function()
	if not is_activewin() then
		return ""
	end

	local m = vim.api.nvim_get_mode().mode
	local current_mode = "%#" .. M.modes[m][2] .. "#" .. " " .. M.modes[m][1]
	local mode_sep1 = "%#" .. M.modes[m][2] .. "Sep" .. "#" .. separators[2]

	return current_mode .. " " .. mode_sep1 .. "%#ST_EmptySpace#" .. separators[2]
end

-- credits to ii14 for str:match func
M.fileInfo = function()
	local icon = " 󰈚 "
	local path = vim.api.nvim_buf_get_name(stbufnr())
	local name = (path == "" and "Empty ") or path:match("([^/\\]+)[/\\]*$")

	if name ~= "Empty " then
		local devicons_present, devicons = pcall(require, "nvim-web-devicons")

		if devicons_present then
			local ft_icon = devicons.get_icon(name)
			icon = (ft_icon ~= nil and " " .. ft_icon) or icon
		end

		name = " " .. name .. " "
	end

	return "%#St_file_info#" .. icon .. name .. "%#St_file_sep#" .. separators[2]
end

M.git = function()
	if not vim.b[stbufnr()].gitsigns_head or vim.b[stbufnr()].gitsigns_git_status then
		return ""
	end

	local git_status = vim.b[stbufnr()].gitsigns_status_dict

	local added = (git_status.added and git_status.added ~= 0) and ("  " .. git_status.added) or ""
	local changed = (git_status.changed and git_status.changed ~= 0) and ("  " .. git_status.changed) or ""
	local removed = (git_status.removed and git_status.removed ~= 0) and ("  " .. git_status.removed) or ""
	local branch_name = "  " .. git_status.head

	return "%#St_gitIcons#" .. branch_name .. added .. changed .. removed
end

-- LSP STUFF
M.LSP_progress = function()
	if not rawget(vim, "lsp") or vim.lsp.status or not is_activewin() then
		return ""
	end

	local Lsp = vim.lsp.util.get_progress_messages()[1]

	if vim.o.columns < 120 or not Lsp then
		return ""
	end

	if Lsp.done then
		vim.defer_fn(function()
			vim.cmd.redrawstatus()
		end, 1000)
	end

	local msg = Lsp.message or ""
	local percentage = Lsp.percentage or 0
	local title = Lsp.title or ""
	local spinners = { "", "󰪞", "󰪟", "󰪠", "󰪢", "󰪣", "󰪤", "󰪥" }
	local ms = vim.loop.hrtime() / 1000000
	local frame = math.floor(ms / 120) % #spinners
	local content = string.format(" %%<%s %s %s (%s%%%%) ", spinners[frame + 1], title, msg, percentage)

	if config.lsprogress_len then
		content = string.sub(content, 1, config.lsprogress_len)
	end

	return ("%#St_LspProgress#" .. content) or ""
end

M.LSP_Diagnostics = function()
	if not rawget(vim, "lsp") then
		return ""
	end

	local errors = #vim.diagnostic.get(stbufnr(), { severity = vim.diagnostic.severity.ERROR })
	local warnings = #vim.diagnostic.get(stbufnr(), { severity = vim.diagnostic.severity.WARN })
	local hints = #vim.diagnostic.get(stbufnr(), { severity = vim.diagnostic.severity.HINT })
	local info = #vim.diagnostic.get(stbufnr(), { severity = vim.diagnostic.severity.INFO })

	errors = (errors and errors > 0) and ("%#St_lspError#" .. " " .. errors .. " ") or ""
	warnings = (warnings and warnings > 0) and ("%#St_lspWarning#" .. "  " .. warnings .. " ") or ""
	hints = (hints and hints > 0) and ("%#St_lspHints#" .. "󰛩 " .. hints .. " ") or ""
	info = (info and info > 0) and ("%#St_lspInfo#" .. "󰋼 " .. info .. " ") or ""

	return errors .. warnings .. hints .. info
end

M.LSP_status = function()
	if rawget(vim, "lsp") then
		for _, client in ipairs(vim.lsp.get_active_clients()) do
			if client.attached_buffers[stbufnr()] and client.name ~= "null-ls" then
				return (vim.o.columns > 100 and "%#St_LspStatus#" .. "   LSP ~ " .. client.name .. " ")
					or "   LSP "
			end
		end
	end
end

M.cwd = function()
	local dir_name = "%#St_cwd_icon#" .. " " .. fn.fnamemodify(fn.getcwd(), ":t") .. " "
	return (
		vim.o.columns > 85
		and ("%#St_cwd_sep#" .. "%#St_cwd_sep#" .. separators[3] .. dir_name .. "%#St_cwd_sep#" .. separators[4])
	) or ""
end

M.cursor_position = function()
	local current_line = fn.line(".", vim.g.statusline_winid)
	local total_line = fn.line("$", vim.g.statusline_winid)
	local text = math.modf((current_line / total_line) * 100) .. tostring("%%")
	text = string.format("%4s", text)

	text = (current_line == 1 and "Top") or text
	text = (current_line == total_line and "Bot") or text

	return "%#St_cwd_sep#" .. " " .. text .. " "
end

M.run = function()
	local modules = {
		M.mode(),
		M.fileInfo(),
		M.git(),

		"%=",
		M.LSP_progress(),
		"%=",

		M.LSP_Diagnostics(),
		M.LSP_status() or "",
		M.cwd(),
		M.cursor_position(),
	}

	if config.overriden_modules then
		config.overriden_modules(modules)
	end

	return table.concat(modules)
end

return M

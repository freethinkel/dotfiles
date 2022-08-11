local present, alpha = pcall(require, "alpha")

if not present then
	return
end

require("base46").load_highlight("alpha")

local function button(sc, txt, keybind)
	local sc_ = sc:gsub("%s", ""):gsub("SPC", "<leader>")

	local opts = {
		position = "center",
		text = txt,
		shortcut = sc,
		cursor = 5,
		width = 36,
		align_shortcut = "right",
		hl_shortcut = "Comment",
		hl = "AlphaButton",
	}

	if keybind then
		opts.keymap = { "n", sc_, keybind, { noremap = true, silent = true } }
	end

	return {
		type = "button",
		val = txt,
		on_press = function()
			local key = vim.api.nvim_replace_termcodes(sc_, true, false, true)
			vim.api.nvim_feedkeys(key, "normal", false)
		end,
		opts = opts,
	}
end

local options = {}

local ascii = {
	"  .--.              ",
	"  |__| .-------.    ",
	"  |=.| |.-----.|    ",
	"  |--| || OFF ||    ",
	"  |  | |'-----'|    ",
	"  |__|~')_____('\"  ",
	"                    ",
}

local function getGreeting(name)
	local tableTime = os.date("*t")
	local hour = tableTime.hour
	local greetingsTable = {
		[1] = "  It's bedtime",
		[2] = "  Good morning",
		[3] = "  Good afternoon",
		[4] = "  Good evening",
		[5] = "望 Good night",
	}
	local greetingIndex = 1
	if hour == 23 or hour < 7 then
		greetingIndex = 1
	elseif hour < 12 then
		greetingIndex = 2
	elseif hour >= 12 and hour < 18 then
		greetingIndex = 3
	elseif hour >= 18 and hour < 21 then
		greetingIndex = 4
	elseif hour >= 21 then
		greetingIndex = 5
	end
	return greetingsTable[greetingIndex] .. ", " .. name
end

local userName = os.getenv("USER")

local greeting = getGreeting(userName)

local plugins = ""
if vim.fn.has("linux") == 1 or vim.fn.has("mac") == 1 then
	local handle = io.popen('fd -d 2 . $HOME"/.local/share/nvim/site/pack/packer" | grep pack | wc -l | tr -d "\n" ')
	if handle == nil then
		return nil
	end
	plugins = handle:read("*a")
	handle:close()

	plugins = plugins:gsub("^%s*(.-)%s*$", "%1")
else
	plugins = "N/A"
end

options.header = {
	type = "text",
	val = ascii,
	opts = {
		position = "center",
		hl = "AlphaHeader",
	},
}

options.buttons = {
	type = "group",
	val = {
		button("SPC f f", "   Search", ":Telescope find_files<CR>"),
		button("p", "   Projects", ":Telescope git_status<CR>"),
		button("SPC f o", "   Recents", ":Telescope oldfiles<CR>"),
		button("SPC f w", "  Find Word  ", ":Telescope live_grep<CR>"),
		button("SPC b m", "  Bookmarks  ", ":Telescope marks<CR>"),
		button("SPC t h", "  Themes  ", ":Telescope themes<CR>"),
		button("SPC e s", "  Settings", ":e $MYVIMRC | :cd %:p:h <CR>"),
		button("q", "   Quit", ":qa!<CR>"),
	},
	opts = {
		spacing = 1,
	},
}

options = require("core.utils").load_override(options, "goolord/alpha-nvim")

-- dynamic header padding
local fn = vim.fn
local marginTopPercent = 0.3
local headerPadding = fn.max({ 2, fn.floor(fn.winheight(0) * marginTopPercent) })

alpha.setup({
	layout = {
		{ type = "padding", val = headerPadding },
		options.header,
		{ type = "text", val = greeting, opts = { position = "center", hl = "String" } },
		{
			type = "text",
			val = "  " .. plugins .. " plugins in total",
			opts = { position = "center", hl = "String" },
		},
		{ type = "padding", val = 2 },
		options.buttons,
	},
	opts = {},
})

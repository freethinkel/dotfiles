local M = {}

local function getNvimTreeWidth()
	for _, win in pairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.bo[vim.api.nvim_win_get_buf(win)].ft == "neo-tree" then
			return vim.api.nvim_win_get_width(win) + 1
		end
	end
	return 0
end

local _mixColorChannel = function(channelA, channelB, amount)
	return (channelA * amount) + (channelB * (1 - amount))
end

local hexToRgb = function(color)
	return {
		tonumber(string.sub(color, 2, 3), 16),
		tonumber(string.sub(color, 4, 5), 16),
		tonumber(string.sub(color, 6, 7), 16),
	}
end

local tohex = function(num)
	local val = string.format("%x", num)
	if string.len(val) == 2 then
		return val
	end

	return "0" .. val
end

M.mixColors = function(colorA, colorB, amount)
	colorA = hexToRgb(colorA)
	colorB = hexToRgb(colorB)
	amount = 1 - amount
	local mixed = {
		_mixColorChannel(colorA[1], colorB[1], amount),
		_mixColorChannel(colorA[2], colorB[2], amount),
		_mixColorChannel(colorA[3], colorB[3], amount),
	}

	return "#" .. tohex(mixed[1]) .. tohex(mixed[2]) .. tohex(mixed[3])
end

M.hi = function(config)
	local name = config[1]
	local cmd = "highlight " .. name

	if config.fg then
		cmd = cmd .. " guifg=" .. config.fg
	end
	if config.bg then
		cmd = cmd .. " guibg=" .. config.bg
	end
	if config.sp then
		cmd = cmd .. " guisp=" .. config.sp
	end
	if config.underline then
		cmd = cmd .. " cterm=" .. "underline"
	end
	if config.undercurl then
		cmd = cmd .. " gui=" .. "undercurl"
	end

	vim.cmd(cmd)
end

M.fix_tabufline = function(modules)
	table.remove(modules, 1)
	table.insert(
		modules,
		1,
		"%#NvimTreeNormal#" .. (vim.g.nvimtree_side == "right" and "" or string.rep(" ", getNvimTreeWidth()))
	)
end

return M

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

function M.vec_union(...)
	local result = {}
	local args = { ... }
	local seen = {}

	for i = 1, select("#", ...) do
		if type(args[i]) ~= "nil" then
			if type(args[i]) ~= "table" and not seen[args[i]] then
				seen[args[i]] = true
				result[#result + 1] = args[i]
			else
				for _, v in ipairs(args[i]) do
					if not seen[v] then
						seen[v] = true
						result[#result + 1] = v
					end
				end
			end
		end
	end

	return result
end

function M.tbl_union_extend(t, ...)
	local res = M.tbl_clone(t)

	local function recurse(ours, theirs)
		-- Get the union of the two tables
		local sub = M.vec_union(ours, theirs)

		for k, v in pairs(ours) do
			if type(k) ~= "number" then
				sub[k] = v
			end
		end

		for k, v in pairs(theirs) do
			if type(k) ~= "number" then
				if type(v) == "table" then
					sub[k] = recurse(sub[k] or {}, v)
				else
					sub[k] = v
				end
			end
		end

		return sub
	end

	for _, theirs in ipairs({ ... }) do
		res = recurse(res, theirs)
	end

	return res
end

function M.tbl_set(t, table_path, value)
	local keys = type(table_path) == "table" and table_path ---@cast table_path string
		or vim.split(table_path, ".", { plain = true })

	local cur = t

	for i = 1, #keys - 1 do
		local k = keys[i]

		if not cur[k] then
			cur[k] = {}
		end

		cur = cur[k]
	end

	cur[keys[#keys]] = value

	return value
end

function M.tbl_access(t, table_path)
	local keys = type(table_path) == "table" and table_path ---@cast table_path string
		or vim.split(table_path, ".", { plain = true })

	local cur = t

	for _, k in ipairs(keys) do
		cur = cur[k]
		if not cur then
			return nil
		end
	end

	return cur
end

function M.tbl_clone(t)
	local clone = {}

	for k, v in pairs(t) do
		clone[k] = v
	end

	return clone
end

function M.tbl_ensure(t, table_path)
	local keys = type(table_path) == "table" and table_path ---@cast table_path string
		or vim.split(table_path, ".", { plain = true })

	local ret = M.tbl_access(t, keys)
	assert(ret == nil or type(ret) == "table", "TypeError :: The table path exists and is of a non-table type!")

	if not ret then
		ret = M.tbl_set(t, keys, {})
	end

	return ret
end

return M

local M = {}
local api = vim.api

local merge_tb = vim.tbl_deep_extend

M.load_config = function()
	local config = require("core.default_config")
	local nvcode_custom_exists, nvcode_custom = pcall(require, "config")

	if nvcode_custom_exists then
		if type(nvcode_custom) == "table" then
			config = merge_tb("force", config, nvcode_custom) or {}
		else
			error("custom must return a table!")
		end
	end

	return config
end

M.load_mappings = function(mappings, mapping_opt)
	local keymap = vim.api.nvim_set_keymap
	local default_opts = { noremap = true, silent = true }

	for mode, map in pairs(mappings) do
		for key, command in pairs(map) do
			keymap(mode, key, command, mapping_opt or default_opts)
		end
	end
end

M.toggle_float_terminal = function()
	vim.cmd("FloatermToggle")
end

-- Custom highlight color
M.get_hl = function(name, no_trans)
	local hl

	if no_trans then
		hl = api.nvim__get_hl_defs(0)[name]
	else
		local id = api.nvim_get_hl_id_by_name(name)

		if id then
			hl = api.nvim_get_hl_by_id(id, true)
		end
	end

	if hl then
		if hl.foreground then
			hl.fg = string.format("#%06x", hl.foreground)
		end
		if hl.background then
			hl.bg = string.format("#%06x", hl.background)
		end
		if hl.special then
			hl.sp = string.format("#%06x", hl.special)
		end

		return hl
	end
end

M.hi_spec_to_data = function(spec)
	local style_attrs = {
		"bold",
		"italic",
		"underline",
		"underlineline",
		"undercurl",
		"underdash",
		"underdot",
		"strikethrough",
		"standout",
		"reverse",
	}
	local res = {}
	local fields = { "fg", "bg", "sp", "ctermfg", "ctermbg", "cterm", "default" }

	for _, field in ipairs(fields) do
		res[field] = spec[field]
	end

	if spec.style then
		local spec_attrs = vim.tbl_add_reverse_lookup(vim.split(spec.style, ","))

		for _, attr in ipairs(style_attrs) do
			res[attr] = spec_attrs[attr] ~= nil
		end
	end

	return res
end

M.hi = function(groups, opt)
	if type(groups) ~= "table" then
		groups = { groups }
	end

	for _, group in ipairs(groups) do
		local def_spec = M.hi_spec_to_data(opt)

		if not opt.explicit then
			def_spec = vim.tbl_extend("force", M.get_hl(group, true) or {}, def_spec)
			def_spec[true] = nil
			def_spec[false] = nil
			def_spec.link = nil
			def_spec.foreground = nil
			def_spec.background = nil
			def_spec.special = nil
		end

		if opt.unlink then
			def_spec.link = -1
		end

		for k, v in pairs(def_spec) do
			if v == "NONE" then
				def_spec[k] = nil
			end
		end

		api.nvim_set_hl(0, group, def_spec)
	end
end

function M.hi_link(from, to, opt)
	if to and tostring(to):upper() == "NONE" then
		to = -1
	end

	opt = vim.tbl_extend("keep", opt or {}, {
		force = true,
	})

	if type(from) ~= "table" then
		from = { from }
	end

	for _, f in ipairs(from) do
		if opt.clear then
			api.nvim_set_hl(0, f, {})
		end

		api.nvim_set_hl(0, f, {
			default = opt.default,
			link = to,
		})
	end
end

return M

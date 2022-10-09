local M = {}

M.options = {
	auto_clean = true,
	compile_on_sync = true,
	git = { clone_timeout = 6000 },
	display = {
		working_sym = "ﲊ",
		error_sym = "✗ ",
		done_sym = " ",
		removed_sym = " ",
		moved_sym = "",
		open_fn = function()
			return require("packer.util").float({ border = "single" })
		end,
	},
}

-- merge overrides if there are any
-- M.options = require("core.utils").load_override(M.options, "wbthomason/packer.nvim")

local normalize_plugins = function(default_plugins)
	local final_table = {}

	for key, _ in pairs(default_plugins) do
		default_plugins[key][1] = key
		final_table[#final_table + 1] = default_plugins[key]
	end

	return final_table
end

M.run = function(plugins)
	local present, packer = pcall(require, "packer")

	if not present then
		return
	end

	plugins = normalize_plugins(plugins)

	packer.init(M.options)

	packer.startup(function(use)
		for _, v in pairs(plugins) do
			use(v)
		end
	end)
end

return M

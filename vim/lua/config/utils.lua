local M = {}

vim.g.mapleader = " "
vim.g.maplocalleader = " "

M.set_keymap = function(mode, shortcut, command, opts)
	local keymap = vim.keymap.set
	local default_opts = { noremap = true, silent = true }
	keymap(mode, shortcut, command, opts or default_opts)
end

local unsafe_set_theme = function(theme)
	vim.cmd('colorscheme ' .. theme)
end

M.set_theme = function(theme)
	pcall(unsafe_set_theme, theme)
end

return M

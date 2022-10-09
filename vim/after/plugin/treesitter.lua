local status, treesitter = pcall(require, 'nvim-treesitter')
if (not status) then
	return
end
treesitter.setup({ auto_install = true })

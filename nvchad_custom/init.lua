-- local autocmd = vim.api.nvim_create_autocmd

-- Auto resize panes when resizing nvim window
-- autocmd("VimResized", {
--   pattern = "*",
--   command = "tabdo wincmd =",
-- })
--
-- TODO:
-- add [mappings
-- fix harpoon tabs
--

-- OTHER
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])
-- WEZTERM
-- vim.cmd([[let &t_Cs = "\e[60m"]])
-- vim.cmd([[let &t_Ce = "\e[24m"]])

vim.cmd("au BufNewFile,BufRead *.pcss set ft=css")
vim.cmd("au BufNewFile,BufRead *.mdx set ft=markdown")

vim.opt.swapfile = false
vim.opt.wrap = false

vim.api.nvim_create_autocmd({ "ColorScheme" }, {
	pattern = "*",
	callback = function()
		require("custom.highlights").override_highlights()
	end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

vim.cmd("au BufNewFile,BufRead *.pcss set ft=scss")
vim.cmd("au BufNewFile,BufRead *.mdx set ft=markdown")

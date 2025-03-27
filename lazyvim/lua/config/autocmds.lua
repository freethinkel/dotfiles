-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
--

vim.cmd("au BufNewFile,BufRead *.pcss set ft=css")
vim.cmd("au BufNewFile,BufRead *.mdx set ft=markdown")
vim.cmd("au BufNewFile,BufRead *.arb set ft=json")
vim.cmd("au BufNewFile,BufRead */.vscode/launch.json set ft=jsonc")
vim.cmd("au BufNewFile,BufRead *.fvmrc set ft=json")

-- vim.api.nvim_create_augroup("jsonc_filetype", { clear = true })
-- vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
--   pattern = ".vscode/launch.json",
--   command = "set filetype=jsonc",
-- })

-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.cmd("au BufNewFile,BufRead *.pcss set ft=css")
vim.cmd("au BufNewFile,BufRead *.mdx set ft=markdown")
vim.cmd("au BufNewFile,BufRead *.arb set ft=json")
vim.cmd("au BufNewFile,BufRead */.vscode/launch.json set ft=jsonc")
vim.cmd("au BufNewFile,BufRead *.fvmrc set ft=json")
vim.cmd("au BufNewFile,BufRead *.ejs set ft=ejs")

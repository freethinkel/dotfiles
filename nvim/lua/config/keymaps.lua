-- Keymaps are automatically loaded on the VeryLazy event
-- -- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- -- Add any additional keymaps here
-- --
local map = vim.keymap.set
local del = vim.keymap.del
local opts = { silent = true, noremap = true }

del("n", "<leader>l")

map("i", "kj", "<Esc>", opts)
map("i", "jk", "<Esc>", opts)
map("i", "jj", "<Esc>", opts)

map("n", "ss", "<cmd>split<cr>", opts)
map("n", "sv", "<cmd>vsplit<cr>", opts)
map("n", "<leader>h", "<cmd>nohlsearch<cr>", opts)

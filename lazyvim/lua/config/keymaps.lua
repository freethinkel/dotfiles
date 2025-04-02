-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

map("i", "jk", "<Esc>")
map("i", "kj", "<Esc>")
map("i", "jj", "<Esc>")

map("n", "<leader>rn", function()
  vim.lsp.but.rename()
end, { desc = "Rename" })
-- { "<leader>cr", vim.lsp.buf.rename, desc = "Rename", has = "rename" },

map("n", "<leader>/", function()
  require("modules.telescope").run()
end, { desc = "Multi grep", remap = true })

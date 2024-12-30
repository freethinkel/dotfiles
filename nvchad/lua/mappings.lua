require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set
local del = vim.keymap.del

del("n", "<leader>rn")
map("n", "<leader>e", ":Neotree toggle<cr>", { desc = "Neotree toggle", silent = true })

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("i", "kj", "<ESC>")
map("i", "jj", "<ESC>")

map("n", "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", { desc = "Go to the previous pane" })
map("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Got to the left pane" })
map("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", { desc = "Got to the down pane" })
map("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", { desc = "Got to the up pane" })
map("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", { desc = "Got to the right pane" })

map("x", "<A-j>", ":m '>+1<cr>gv-gv", { desc = "Move down", noremap = true, silent = true })
map("x", "<A-k>", ":m '<-2<CR>gv-gv", { desc = "Move up", noremap = true, silent = true })

map("n", "<A-j>", ":m .+1<CR>==", { desc = "Move down" })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Move up" })

map("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })

-- Comment
del("n", "<leader>/")
del("v", "<leader>/")
map("n", "<leader>/", function()
  require("modules.telescope").run()
end, { desc = "Multi grep", remap = true })

-- BUFFERS
del("n", "<leader>x")
map("n", "<leader>bd", function()
  require("nvchad.tabufline").close_buffer()
end, { desc = "Delete buffer" })

map("n", "<S-l>", function()
  require("nvchad.tabufline").next()
end, { desc = "buffer goto next" })

map("n", "<S-h>", function()
  require("nvchad.tabufline").prev()
end, { desc = "buffer goto prev" })

-- INTERNAL
map("n", "<leader>fg", function()
  require("modules.telescope").run()
end, { desc = "[F]ind [G]rep" })

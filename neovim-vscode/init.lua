vim.opt.clipboard = "unnamedplus"

local map = vim.keymap.set
local del = vim.keymap.del
local opts = { silent = true, noremap = true }

local vscode = require("vscode-neovim")

map({ "x", "n" }, "<C-h>", function()
	vscode.call("workbench.action.navigateLeft")
end, opts)
map({ "x", "n" }, "<C-j>", function()
	vscode.call("workbench.action.navigateDown")
end, opts)
map({ "x", "n" }, "<C-k>", function()
	vscode.call("workbench.action.navigateUp")
end, opts)
map({ "x", "n" }, "<C-l>", function()
	vscode.call("workbench.action.navigateRight")
end, opts)

map("n", "H", function()
	vscode.call("workbench.action.previousEditor")
end)

map("n", "L", function()
	vscode.call("workbench.action.nextEditor")
end)

map({ "n", "v" }, "<Space>", function()
	vscode.call("whichkey.show")
end, opts)

map("n", "<Tab>", "<cmd>Tabnext<CR>")
map("n", "<S-Tab>", "<cmd>Tabprev<CR>")
map("n", "gd", function()
	vscode.call("editor.action.revealDefinition")
end)
map("n", "K", function()
	vscode.call("editor.action.showHover")
end)

map("n", "<A-j>", function()
	vscode.call("editor.action.moveLinesDownAction")
end)
map("n", "<A-k>", function()
	vscode.call("editor.action.moveLinesUpAction")
end)

map("x", "<A-j>", ":m '>+1<CR>gv-gv")
map("x", "<A-k>", ":m '<-2<CR>gv-gv")
map("n", "<Esc>", ":nohl<CR>", { silent = true })

-- LSP
map("n", "[d", function() vscode.call("editor.action.marker.prevInFiles") end)
map("n", "]d", function() vscode.call("editor.action.marker.next") end)
map("n", 'gr', function()
	vscode.call("editor.action.goToReferences")
end)

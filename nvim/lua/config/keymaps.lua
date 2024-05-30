local map = vim.keymap.set
local opts = { silent = true, noremap = true }

map("i", "kj", "<Esc>", opts)
map("i", "jk", "<Esc>", opts)
map("i", "jj", "<Esc>", opts)

map("n", "ss", "<cmd>split<cr>", opts)
map("n", "sv", "<cmd>vsplit<cr>", opts)
map("n", "<Esc>", "<cmd>nohlsearch<cr>", opts)

map("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Buffers
map("n", "<leader>bb", "<cmd>Telescope buffers<cr>", { desc = "List [B]uffers" })
map("n", "<leader>bd", function()
	local allBuffers = require("config.utils").get_buffers()
	local currentBuffer = vim.api.nvim_get_current_buf()

	vim.api.nvim_set_current_buf(
		require("config.utils").getNextCycleValue(
			allBuffers,
			require("config.utils").indexOf(allBuffers, currentBuffer)
		)
	)
	vim.api.nvim_buf_delete(currentBuffer, {})
end, { desc = "[B]uffer delete" })

map("n", "[b", "<cmd>bp<cr>", { desc = "Go to previous [B]uffer " })
map("n", "]b", "<cmd>bn<cr>", { desc = "Go to next [B]buffer" })
map("n", "<leader>co", function()
	local buffer_ids = require("config.utils").get_buffers()

	for _, buf in ipairs(buffer_ids) do
		if buf ~= vim.api.nvim_get_current_buf() then
			vim.api.nvim_buf_delete(buf, {})
		end
	end
end, { desc = "[C]lose [O]ther buffers" })

map("x", "<A-j>", ":m '>+1<cr>gv-gv", { desc = "Move down", noremap = true, silent = true })
map("x", "<A-k>", ":m '<-2<CR>gv-gv", { desc = "Move up", noremap = true, silent = true })

map("n", "<A-j>", ":m .+1<CR>==", { desc = "Move down" })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Move up" })

-- ["j"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },
-- ["k"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
-- ["<Up>"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
-- ["<Down>"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },
--VISUAL
map("v", "<", "<gv", { noremap = true, silent = true })
map("v", ">", ">gv", { noremap = true, silent = true })
map("v", "<Up>", 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', { desc = "Move up", expr = true })
map("v", "<Down>", 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', { desc = "Move down", expr = true })

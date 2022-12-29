local nvmap = vim.keymap.set
local map = require("utils").set_map

vim.g.mapleader = " "

nvmap("i", "jj", "<Esc>")
nvmap("i", "jk", "<Esc>")
nvmap("i", "kj", "<Esc>")
nvmap("v", "p", 'p:let @+=@0<CR>:let @"=@0<CR>', { silent = true })

map({
  ["<leader>e"] = { "<cmd>NvimTreeFocus<cr>", "File Explorer" },
  ["H"] = { "<cmd>BufferLineCyclePrev<cr>", "Prev tab" },
  ["L"] = { "<cmd>BufferLineCycleNext<cr>", "Next tab" },
  ["x"] = { function()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.cmd("BufferLineCyclePrev");
    vim.cmd("confirm bd" .. bufnr)
  end, "Close buffer" }
})

map({
  ["<leader>/"] = { function() require("Comment.api").toggle.linewise.current() end, "Toggle comment" }
})

map({
  ["<leader>/"] = {
    "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
    "Toggle comment",
  },
}, { mode = "v" })


map({
  ["<leader>f"] = {
    name = "Telescope",
    ["f"] = { function() require('telescope.builtin').find_files() end, "Find files" },
    ["w"] = { function() require('telescope.builtin').live_grep() end, "Find words" },
    ["r"] = { function() require('telescope.builtin').oldfiles() end, "Recents" },
  }
})

map({
  ["<leader>p"] = {
    name = "Packer",
    ['s'] = { "<cmd>PackerSync<cr>", "Packer Sync" }
  }
})

map({
  ["<leader>g"] = {
    name = "Git",
    ["l"] = { function() require("modules.lazygit").toggle() end, "Toggle lazygit" }
  }
})

local status, bufferline = pcall(require, "bufferline")

if not status then
  return
end

bufferline.setup({
  options = {
    offsets = {
      {
        filetype = "NvimTree",
        text = "Explorer",
        highlight = "Directory",
        text_align = "left",
      },
    },
  },
})

local keymap = require("config.utils").set_keymap

keymap("n", "<S-h>", "<Cmd>BufferLineCyclePrev<CR>")
keymap("n", "<S-l>", "<Cmd>BufferLineCycleNext<CR>")
keymap("n", "<leader>x", "<Cmd>BufferLineCloseRight<CR>")

-- local bufnr = vim.api.nvim_get_current_buf()
-- vim.cmd("BufferLineCyclePrev")
-- vim.cmd("bd" .. bufnr)

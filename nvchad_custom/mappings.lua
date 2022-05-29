local M = {}

M.bufferline = {
  n = {
    ["<S-l>"] = { "<cmd> BufferLineCycleNext <CR>", "  cycle next buffer" },
    ["<S-h>"] = { "<cmd> BufferLineCyclePrev <CR>", "  cycle prev buffer" },
    ["<C-j>"] = {"<cmd> TmuxNavigateDown <CR>", "Tmux navigate down"},
  }
}

return M

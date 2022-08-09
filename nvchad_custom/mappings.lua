local M = {}

M.bufferline = {
  n = {
    ["<S-l>"] = { "<cmd> Tbufnext <CR>", "  cycle next buffer" },
    ["<S-h>"] = { "<cmd> Tbufprev <CR>", "  cycle prev buffer" },
    ["<C-j>"] = {"<cmd> TmuxNavigateDown <CR>", "Tmux navigate down"},
  }
}

return M

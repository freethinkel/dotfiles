if vim.g.neovide then
  require("config.neovide")
end

vim.g.root_spec = { { ".git", "lua" }, "lsp", "cwd" }

vim.opt.swapfile = false
vim.g.snacks_animate = false

vim.g.lazyvim_prettier_needs_config = false
vim.g.lazyvim_eslint_auto_format = true
vim.opt.clipboard = "unnamedplus"

if vim.g.neovide then
  require("config.neovide")
end

vim.g.root_spec = { { ".git", "lua" }, "lsp", "cwd" }

vim.opt.swapfile = false
vim.g.snacks_animate = false

vim.g.lazyvim_prettier_needs_config = false
vim.g.lazyvim_eslint_auto_format = true
vim.opt.clipboard = "unnamedplus"

if vim.loop.os_uname().sysname ~= "Darwin" then
  vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
      -- vim.highlight.on_yank()
      local copy_to_unnamedplus = require("vim.ui.clipboard.osc52").copy("+")
      copy_to_unnamedplus(vim.v.event.regcontents)
      local copy_to_unnamed = require("vim.ui.clipboard.osc52").copy("*")
      copy_to_unnamed(vim.v.event.regcontents)
    end,
  })
end

require "nvchad.options"

-- add yours here!

local o = vim.o
o.cursorlineopt = "both" -- to enable cursorline!

vim.opt.swapfile = false
vim.opt.wrap = false
vim.api.nvim_set_var("t_Ce", "`e[4:0m")
-- printf '\e[4:3mUnderlined\n'

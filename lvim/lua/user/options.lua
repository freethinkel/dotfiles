vim.cmd("au BufNewFile,BufRead *.pcss set ft=postcss")
vim.opt.fillchars                                   = vim.opt.fillchars + "diff:╱" + "eob: "

lvim.log.level                                      = "warn"
lvim.leader                                         = "space"
vim.opt.timeoutlen                                  = 150

lvim.format_on_save.enabled                         = true

lvim.builtin.alpha.active                           = true
lvim.builtin.alpha.mode                             = "dashboard"
lvim.builtin.terminal.active                        = true
lvim.builtin.nvimtree.setup.view.side               = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false

-- lvim.builtin.nvimtree.setup.renderer.icons.webdev_colors = false

require("user.configs.gitsigns")
require("user.configs.treesitter")

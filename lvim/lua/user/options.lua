vim.cmd("au BufNewFile,BufRead *.pcss set ft=scss")
vim.cmd("au BufNewFile,BufRead *.mdx set ft=markdown")
vim.opt.fillchars                                    = vim.opt.fillchars + "diff:╱" + "eob: "

lvim.log.level                                       = "warn"
lvim.leader                                          = "space"
vim.opt.timeoutlen                                   = 150

lvim.format_on_save.enabled                          = true

lvim.builtin.alpha.active                            = true
lvim.builtin.alpha.mode                              = "dashboard"
lvim.builtin.alpha.dashboard.section.header.val      = function()
  return {
    [[  ▓████████████▓  ]],
    [[ ▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓ ]],
    [[ █▒▒▒▒▒▒▒▒▒▒▒▒▒▒█ ]],
    [[ █▒▒▓██▓▒▒▓██▓▒▒█ ]],
    [[ █▒▒▓██▓▒▒▓██▓▒▒█ ]],
    [[ █▒▒▒▒▒▒▒▒▒▒▒▒▒▒█ ]],
    [[ ▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓ ]],
    [[  ▓████████████▓  ]]
  }
end
lvim.builtin.alpha.dashboard.section.buttons.entries = {
  { "f", lvim.icons.ui.FindFile .. "  Find File",    "<CMD>Telescope find_files<CR>" },
  { "r", lvim.icons.ui.History .. "  Recent files",  ":Telescope oldfiles <CR>" },
  { "g", lvim.icons.ui.History .. "  Changed files", ":Telescope git_status<CR>" },
  { "n", lvim.icons.ui.NewFile .. "  New File",      "<CMD>ene!<CR>" },
  { "p", lvim.icons.ui.Project .. "  Projects ",     "<CMD>Telescope projects<CR>" },
  { "t", lvim.icons.ui.FindText .. "  Find Text",    "<CMD>Telescope live_grep<CR>" },
  {
    "c",
    lvim.icons.ui.Gear .. "  Configuration",
    "<CMD>edit " .. require("lvim.config"):get_user_config_path() .. " <CR>",
  },
  { "q", lvim.icons.ui.Close .. "  Quit", "<CMD>quit<CR>" },
}
lvim.builtin.terminal.active                         = true
lvim.builtin.nvimtree.setup.view.side                = "left"
lvim.builtin.nvimtree.setup.view.width               = 50
lvim.builtin.nvimtree.setup.renderer.icons.show.git  = false
lvim.builtin.nvimtree.setup.tab.sync.open            = true
lvim.builtin.nvimtree.setup.tab.sync.close           = true
lvim.builtin.nvimtree.setup.git.timeout              = 500

-- lvim.builtin.nvimtree.setup.renderer.icons.webdev_colors = false

require("user.configs.gitsigns")
require("user.configs.treesitter")

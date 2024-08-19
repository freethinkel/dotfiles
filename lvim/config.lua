-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Example configs: https://github.com/LunarVim/starter.lvim
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny
--

require("configs.gitsigns")
require("configs.lualine")
require("configs.lsp")
require("mappings")

lvim.colorscheme            = "nules-dark"
-- require("themes")

lvim.format_on_save.enabled = true
vim.opt.fillchars           = vim.opt.fillchars + "diff:╱" + "eob: "


lvim.builtin.alpha.dashboard.section.header.val = function()
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
-- vim.print(lvim.builtin.alpha.dashboard.section.buttons.entries)

table.insert(lvim.builtin.alpha.dashboard.section.buttons.entries, {
  "s", "Restore session", ":Telescope oldfiles <CR><CR>"
});

lvim.builtin.nvimtree.setup.view.side               = "left"
lvim.builtin.nvimtree.setup.view.width              = 40
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false
lvim.builtin.nvimtree.setup.tab.sync.open           = true
lvim.builtin.nvimtree.setup.tab.sync.close          = true
lvim.builtin.nvimtree.setup.git.timeout             = 500
lvim.builtin.dap.active                             = true

lvim.plugins                                        = {
  {
    "shaunsingh/nord.nvim"
  },
  {
    "mg979/vim-visual-multi",
    lazy = false,
  },
  {
    dir = "~/Developer/dev/pet/nules.nvim",
  },
  require("configs.flutter"),
}

vim.keymap.set("n", "gD", "<CMD>Glance definitions<CR>")
vim.keymap.set("n", "gR", "<CMD>Glance references<CR>")
vim.keymap.set("n", "gY", "<CMD>Glance type_definitions<CR>")
vim.keymap.set("n", "gM", "<CMD>Glance implementations<CR>")

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            { "gr", "<CMD>Glance references<CR>" },
            { "gd", "<CMD>Glance definitions<CR>" },
            { "gy", "<CMD>Glance type_definitions<CR>" },
            { "gm", "<CMD>Glance implementations<CR>" },
          },
        },
      },
    },
  },
  {
    "dnlhc/glance.nvim",
    cmd = "Glance",
    keys = {},
  },
}
--
--
-- {
--   "<leader>fp",
--   function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root }) end,
--   desc = "Find Plugin File",
-- },

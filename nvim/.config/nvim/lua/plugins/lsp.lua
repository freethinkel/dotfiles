vim.keymap.set("n", "gD", "<CMD>Glance definitions<CR>")
vim.keymap.set("n", "gR", "<CMD>Glance references<CR>")
vim.keymap.set("n", "gY", "<CMD>Glance type_definitions<CR>")
vim.keymap.set("n", "gM", "<CMD>Glance implementations<CR>")

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false },
      servers = {
        -- flutter-tools starts dartls itself (with the fvm SDK); disable the
        -- lspconfig copy so it doesn't try `dart` from PATH and fail.
        dartls = { enabled = false },
        stylelint = {
          filetypes = { "css", "scss", "less", "sass", "pcss", "vue", "svelte" },
        },
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

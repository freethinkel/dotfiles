local state = false

return {
  {
    dir = "~/Developer/dev/pet/nules.nvim",
  },
  {
    "shaunsingh/nord.nvim",
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
  },
  {
    "cdmill/neomodern.nvim",
    lazy = true,
    priority = 1000,
    config = function()
      require("neomodern").setup({
        style = "campfire", -- choose between 'iceclimber', 'coffeecat', 'darkforest', 'campfire', 'roseprime', 'daylight'
      })
      require("neomodern").load()
    end,
  },
  { "rebelot/kanagawa.nvim" },
  { "rose-pine/neovim", name = "rose-pine" },
  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "noirbuddy",
      -- colorscheme = "kanagawa",
      -- colorscheme = "catppuccin",
      -- colorscheme = "rose-pine-dawn",
      -- colorscheme = "nules-dark",
      colorscheme = "snowfall-dark",
    },
  },
}

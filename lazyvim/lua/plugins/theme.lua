local state = false

local current_theme = function()
  -- return "gruvbox"
  return "adwaita"

  -- if vim.o.background == "light" then
  --   -- return "gruvbox"
  --   return "github_light"
  -- else
  --   -- return "gruvbox"
  --   return "github_dark_dimmed"
  --   -- return "catppuccin-mocha"
  -- end
end

return {
  {
    "f-person/auto-dark-mode.nvim",
    opts = {
      set_dark_mode = function()
        vim.api.nvim_set_option_value("background", "dark", {})
        vim.cmd.colorscheme("vim")
        vim.cmd.colorscheme(current_theme())
      end,
      set_light_mode = function()
        vim.api.nvim_set_option_value("background", "light", {})
        vim.cmd.colorscheme(current_theme())
      end,
    },
  },
  { "zenbones-theme/zenbones.nvim", dependencies = "rktjmp/lush.nvim" },
  { "projekt0n/github-nvim-theme" },
  {
    -- dir = "~/Developer/dev/pet/snowfall.nvim",
    "freethinkel/snowfall.nvim",
    --
  },
  { "Mofiqul/adwaita.nvim" },
  { "ellisonleao/gruvbox.nvim" },
  {
    "shaunsingh/nord.nvim",
  },
  {
    "AlexvZyl/nordic.nvim",
    lazy = false,
    priority = 1000,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
  },
  { "Shatur/neovim-ayu" },
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
      colorscheme = current_theme(),
    },
  },
}

lvim.plugins = {
  { "mg979/vim-visual-multi" },
  { "christoomey/vim-tmux-navigator" },
  { "sainnhe/gruvbox-material" },
  {
    "akinsho/flutter-tools.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim",
    },
    config = function()
      require("user.configs.lsp").flutter()
    end,
  },
  { "imsnif/kdl.vim" },
  {
    "sindrets/diffview.nvim",
    event = "BufRead",
  },
  {
    "windwp/nvim-ts-autotag",
    config = function()
      require("nvim-ts-autotag").setup()
    end,
  },
  {
    "glepnir/lspsaga.nvim",
    branch = "main",
    config = function()
      require("user.configs.lsp").lspsaga()
    end,
  },
  { "nyoom-engineering/oxocarbon.nvim" },
  { "catppuccin/nvim",                 name = "catppuccin" },
  { "stephenway/postcss.vim" },
  {
    "loctvl842/monokai-pro.nvim",
    config = function()
      require("user.configs.themes").monokai_pro()
    end,
  },
  {
    "projekt0n/github-nvim-theme",
    version = "v0.0.7",
    config = function()
      require("user.configs.themes").github()
    end,
  },
  {
    "mountain-theme/vim",
    lazy = false
  },
  -- OWN THEME
  {
    dir = "~/Developer/dev/pet/oshmes.nvim/",
  },
  -- {
  --   "freethinkel/oshmes.nvim"
  -- },
  { "shaunsingh/nord.nvim" },
  { 'rose-pine/neovim',               name = 'rose-pine' },
  { "olivercederborg/poimandres.nvim" },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPre" },
    config = function()
      require("user.configs.todo-comments").setup()
    end,
  },
  { "nvim-treesitter/playground" },
  {
    "phaazon/hop.nvim",
    config = function()
      require("user.configs.hop").setup()
    end
  },
  {
    "nvim-pack/nvim-spectre",
    config = function()
      require("user.configs.spectre").setup()
    end
  }
}

require("user.configs.dap_ui")

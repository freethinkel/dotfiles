require("utils").setup_lazy()

require("lazy").setup({
  -- THEMES
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
  },
  {
    "navarasu/onedark.nvim",
    priority = 1000,
  },
  { "catppuccin/nvim", name = "catppuccin" },
  -- TELESCOPE
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Telescope",
  },
  -- LSP
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lua",
    },
    config = function()
      require("configs.cmp").setup()
    end,
  },
  { "L3MON4D3/LuaSnip" },
  {
    "williamboman/mason.nvim",
    dependencies = { "williamboman/mason-lspconfig.nvim", "neovim/nvim-lspconfig" },
    build = ":MasonUpdate",
    config = function()
      require("configs.lsp").setup()
    end,
  },
  {
    "jay-babu/mason-null-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "jose-elias-alvarez/null-ls.nvim",
    },
    config = function()
      require("configs.lsp").null_ls()
    end,
  },
  {
    "glepnir/lspsaga.nvim",
    event = "LspAttach",
    config = function()
      require("configs.lsp").lspsaga()
    end,
    dependencies = {
      { "nvim-tree/nvim-web-devicons" },
      --Please make sure you install markdown and markdown_inline parser
      { "nvim-treesitter/nvim-treesitter" },
    },
  },
  {
    "akinsho/flutter-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("configs.lsp").flutter()
    end,
  },
  { "mfussenegger/nvim-dap" },
  -- OTHER
  {
    "nvim-tree/nvim-web-devicons",
    config = function()
      require("configs.devicons").setup()
    end
  },
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require("configs.lualine").setup()
    end,
  },
  {
    "numToStr/Comment.nvim",
    config = function()
      require("configs.comment").setup()
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v2.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("configs.file_explorer").setup()
    end,
  },
  {
    "windwp/nvim-autopairs",
    config = function()
      require("configs.autopairs").setup()
    end,
  },
  {
    "aserowy/tmux.nvim",
    config = function()
      require("tmux").setup()
    end,
  },
  -- MAPPINGS
  {
    "folke/which-key.nvim",
    config = require("configs.which_key").setup,
  },
  -- GIT
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("configs.gitsigns").setup()
    end,
  },
})

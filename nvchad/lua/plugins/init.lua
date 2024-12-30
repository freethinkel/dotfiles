return {
  {
    "stevearc/conform.nvim",
    lazy = false,
    -- event = "BufWritePre", -- uncomment for format on save
    opts = {
      format_on_save = {
        -- These options will be passed to conform.format()
        timeout_ms = 300,
        lsp_fallback = true,
      },
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        sass = { "prettier" },
        pcss = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        javascriptreact = { "prettier" },
        svelte = { "svelte" }, -- auto format with lsp
        svg = { "prettier" },
      },
    },
  },
  {
    "folke/neodev.nvim",
    lazy = true,
  },
  { "christoomey/vim-tmux-navigator", lazy = false },
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("configs.lspconfig").setup()
    end,
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "stylua",
        "html-lsp",
        "css-lsp",
        "prettier",
      },
    },
  },
  {
    "windwp/nvim-ts-autotag",
    config = function()
      require("nvim-ts-autotag").setup()
    end,
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPre" },
    config = function()
      require("todo-comments").setup()
    end,
  },
  {
    "phaazon/hop.nvim",
    lazy = false,
    config = function()
      require("hop").setup()
    end,
  },
  {
    "mg979/vim-visual-multi",
    lazy = false,
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
  },
  {
    "lukas-reineke/headlines.nvim",
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = true, -- or `opts = {}`
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPost",
    opts = {
      throttle = true,
      max_lines = 0,
      patterns = {
        default = {
          "class",
          "function",
          "method",
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "html",
        "css",
        "javascript",
        "typescript",
        "tsx",
        "c",
        "markdown",
        "markdown_inline",
      },
      highlight = {
        enable = true,
      },
      auto_install = true,
      autotag = {
        enable = true,
      },
      indent = { enable = false, disable = { "yaml", "python", "dart" } },
    },
  },
}

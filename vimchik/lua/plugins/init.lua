local plugins = {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("plugins.configs.whichkey")
    end
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
      require("plugins.configs.neotree")
    end
  },
  -- LSP
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("plugins.configs.gitsigns")
    end
  },
  {
    "nvim-treesitter/nvim-treesitter",
    config = function()
      require("plugins.configs.treesitter")
    end
  },
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
      require("plugins.configs.cmp")
    end,
  },
  { "L3MON4D3/LuaSnip" },
  {
    "williamboman/mason.nvim",
    dependencies = { "williamboman/mason-lspconfig.nvim", "neovim/nvim-lspconfig" },
    build = ":MasonUpdate",
    config = function()
      require("plugins.configs.lsp").setup()
    end,
  },
  {
    "jose-elias-alvarez/null-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("plugins.configs.lsp").null_ls()
    end,
  },
  {
    "imsnif/kdl.vim",
    event = { "BufEnter *.kdl" },
  },
  {
    "glepnir/lspsaga.nvim",
    event = "LspAttach",
    config = function()
      require("plugins.configs.lsp").lspsaga()
    end,
    dependencies = {
      { "nvim-tree/nvim-web-devicons" },
      { "nvim-treesitter/nvim-treesitter" },
    },
  },
  {
    "akinsho/flutter-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("plugins.configs.lsp").flutter()
    end,
  },
  { "mfussenegger/nvim-dap" },
  -- LSPEND
  {
    "aserowy/tmux.nvim",
    config = function()
      require("tmux").setup({
        copy_sync = {
          enable = false,
        }
      })
    end,
  },
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.2',
    dependencies = { "nvim-treesitter/nvim-treesitter", "gbrlsnchs/telescope-lsp-handlers.nvim" },
    init = function()
      require("core.utils").load_mappings("telescope")
    end,
    config = function()
      require("plugins.configs.telescope")
    end
  },
  {
    "numToStr/Comment.nvim",
    keys = {
      { "gcc", mode = "n",          desc = "Comment toggle current line" },
      { "gc",  mode = { "n", "o" }, desc = "Comment toggle linewise" },
      { "gc",  mode = "x",          desc = "Comment toggle linewise (visual)" },
      { "gbc", mode = "n",          desc = "Comment toggle current block" },
      { "gb",  mode = { "n", "o" }, desc = "Comment toggle blockwise" },
      { "gb",  mode = "x",          desc = "Comment toggle blockwise (visual)" },
    },
    init = function()
      require("core.utils").load_mappings("comment")
    end,
    config = function(_, opts)
      require("Comment").setup(opts)
    end,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufRead", "BufWinEnter", "BufNewFile" },
    config = function()
      require("core.utils").load_mappings("blankline")
      require("plugins.configs.indent-blankline")
    end,
  },
  {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup({
        fast_wrap = {},
        disable_filetype = { "TelescopePrompt", "vim" },
      })

      -- setup cmp for autopairs
      local cmp_autopairs = require "nvim-autopairs.completion.cmp"
      require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },
  {
    'goolord/alpha-nvim',
    event = "VimEnter",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require("plugins.configs.alpha")
      -- require("alpha").setup(require("alpha.themes.startify").config)
    end
  },
  {
    "mg979/vim-visual-multi",
    event = "BufEnter",
    config = function()
      vim.g.VM_highlight_matches = ''
    end
  },
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    config = function()
      require("zen-mode").setup({
        window = {
          width = 0.8,
        },
      })
    end,
  },
  {
    "nvim-pack/nvim-spectre",
    config = function()
      require("spectre").setup()
    end,
  },
  {
    "NvChad/nvim-colorizer.lua",
    config = function()
      require("plugins.configs.colorizer")
      -- require("colorizer").setup(opts)

      -- execute colorizer as soon as possible
      -- vim.defer_fn(function()
      --   require("colorizer").attach_to_buffer(0)
      -- end, 0)
    end,
  },
  -- THEMES
  { 'rose-pine/neovim', name = 'rose-pine' },
  -- { "freethinkel/oshmes.nvim", },
  {
    dir = "~/Developer/dev/pet/oshmes.nvim/",
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  }
}

return plugins;

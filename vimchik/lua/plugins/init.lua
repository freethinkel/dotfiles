require("utils").setup_packer({
  ["nvim-lua/plenary.nvim"] = {},
  ["folke/which-key.nvim"] = {
    config = require("plugins.configs.which_key").setup
  },
  ['akinsho/bufferline.nvim'] = {
    config = require("plugins.configs.bufferline").setup,
    tag = "v3.*",
    requires = 'nvim-tree/nvim-web-devicons'
  },
  ["shaunsingh/nord.nvim"] = {
    config = require("plugins.configs.theme").nord
  },
  ["nvim-tree/nvim-tree.lua"] = {
    requires = { 'nvim-tree/nvim-web-devicons' },
    config = require("plugins.configs.nvim-tree").setup
  },
  ["windwp/nvim-autopairs"] = {
    config = require("plugins.configs.autopairs").setup
  },
  ["aserowy/tmux.nvim"] = {
    config = function() require("tmux").setup() end
  },
  ["nvim-treesitter/nvim-treesitter"] = {
    run = ":TSUpdate",
    config = require("plugins.configs.treesitter").setup
  },
  ["nvim-telescope/telescope.nvim"] = {
    requires = { { 'nvim-lua/plenary.nvim' } },
    config = require("plugins.configs.telescope").setup
  },
  ["numToStr/Comment.nvim"] = {
    config = require("plugins.configs.comment").setup
  },
  -- LANG SUPPORT
  ["styled-components/vim-styled-components"] = {},
  -- GIT
  ["lewis6991/gitsigns.nvim"] = {
    config = require("plugins.configs.gitsigns").setup
  },
  -- LSP
  -- LSP Support
  ['neovim/nvim-lspconfig'] = {},
  ['williamboman/mason.nvim'] = {
    config = require("plugins.configs.lsp").mason
  },
  ['williamboman/mason-lspconfig.nvim'] = {
    after = "nvim-lspconfig",
    config = function()
      require("plugins.configs.lsp").mason_lspconfig()
    end
  },
  -- Autocompletion
  ['hrsh7th/nvim-cmp'] = {
    config = require("plugins.configs.cmp").setup
  },
  ['hrsh7th/cmp-buffer'] = {},
  ['hrsh7th/cmp-path'] = {},
  ['saadparwaiz1/cmp_luasnip'] = {},
  ['hrsh7th/cmp-nvim-lsp'] = {},
  ['hrsh7th/cmp-nvim-lua'] = {},

  -- Snippets
  ['L3MON4D3/LuaSnip'] = {},
  ['rafamadriz/friendly-snippets'] = {},
  -- LSPEND
  ["jxnblk/vim-mdx-js"] = {}
})

return {
  ["evanleck/vim-svelte"] = {},
  ["jose-elias-alvarez/null-ls.nvim"] = {
    after = "nvim-lspconfig",
    config = function()
     require("custom.plugins.null-ls").setup()
    end,
  },
  ['jiangmiao/auto-pairs'] = {},
  ['pantharshit00/vim-prisma'] = {},
  ['christoomey/vim-tmux-navigator'] = {},
  ['stephenway/postcss.vim'] = {},
  ['thosakwe/vim-flutter'] = {},
  ['styled-components/vim-styled-components'] = {},
  ["goolord/alpha-nvim"] = {
    disable = false,
    config = function()
      require("custom.plugins.alpha")
    end
  },
  ['jxnblk/vim-mdx-js'] = {},
  ['projekt0n/github-nvim-theme'] = {},
  ["neovim/nvim-lspconfig"] = {
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.plugins.lspconfig"
    end,
  },
}

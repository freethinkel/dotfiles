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
  ['christoomey/vim-tmux-navigator'] = {}
}

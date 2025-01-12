return {
  {
    "jedrzejboczar/exrc.nvim",
    dependencies = { "neovim/nvim-lspconfig" }, -- (optional)
    config = true,
    opts = { --[[ your config ]]
      exrc_name = ".nvim.lua", -- Name of exrc files to use
    },
  },
}

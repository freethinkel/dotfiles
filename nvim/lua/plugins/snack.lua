-- lazy.nvim
return {
  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      explorer = {},
      image = {
        enabled = true,
        doc = {
          inline = true,
          float = true,
        },
      },
      picker = {
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
          },
        },
      },
    },
  },
}

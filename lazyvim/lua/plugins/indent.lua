local highlight = {
  "NonText",
}

return {
  {
    "lukas-reineke/indent-blankline.nvim",
    enabled = false,
    main = "ibl",
    ---@module "ibl"
    ---@type ibl.config
    opts = {
      -- indent = { highlight = highlight, char = "" },
      -- whitespace = {
      --   highlight = highlight,
      --   remove_blankline_trail = false,
      -- },
      -- scope = { enabled = false },
    },
  },
}

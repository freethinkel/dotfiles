return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    -- stylua: ignore
    keys = {
      { "fw", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "s", false },
      { "s", false },
    },
  },
}

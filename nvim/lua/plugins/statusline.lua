return {
  {
    "b0o/incline.nvim",
    opts = {},
  },
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        icons_enabled = true,
        theme = "auto",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        ignore_focus = {},
        always_divide_middle = true,
        globalstatus = true,
      },
      sections = {
        lualine_b = { { "branch", icon = "" }, "diff", "diagnostics" },
      },
    },
  },
}

-- local separators = { "", "", "", "" }

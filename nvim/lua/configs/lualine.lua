local M = {}

M.setup = function()
  local lualine = require("lualine")

  ---@diagnostic disable-next-line: redundant-parameter
  lualine.setup({
    options = {
      theme = "auto",
      globalstatus = true,
      section_separators = '',
      component_separators = ''
    },
    sections = {
      lualine_a = {
        {
          function()
            return " " .. vim.api.nvim_get_mode()['mode']:upper() .. " "
          end,
          padding = { left = 0, right = 0 },
          color = {},
          cond = nil,
        },
      },
      lualine_b = { 'branch', 'diff' },
      lualine_x = { "diagnostics" },
      lualine_y = {
        "searchcount",
        "encoding",
        {
          "filetype",
          colored = false,
        },
        "progress",
      },
      lualine_z = {
        {
          "location",
          padding = { left = 0, right = 1 },
        },
      }
    }
  })
end


return M

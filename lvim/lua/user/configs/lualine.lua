local M = {}

M.setup = function()
  local lualine_components                = require("lvim.core.lualine.components")
  lvim.builtin.lualine.style              = "lvim"
  lvim.builtin.lualine.sections.lualine_a = {
    {
      function()
        return " " .. vim.api.nvim_get_mode()["mode"]:upper() .. " "
      end,
      padding = { left = 0, right = 0 },
      color = {},
      cond = nil,
    },
  }
  lvim.builtin.lualine.sections.lualine_x = {
    lualine_components.diagnostics,
  }
  lvim.builtin.lualine.sections.lualine_y = {
    "searchcount",
    "encoding",
    {
      "filetype",
      colored = false,
    },
    {
      "progress",
      separator = { left = "" },
    },
  }
  lvim.builtin.lualine.sections.lualine_z = {
    {
      "location",
      padding = { left = 0, right = 1 },
    },
  }
end

return M

local M = {}

M.setup = function()
  local status, lualine = pcall(require, "lualine")
  if not status then
    return
  end

  local config = require("core.utils").load_config()

  lualine.setup({
    options = {
      globalstatus = true,
      icons_enabled = true,
      theme = config.ui.theme,
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", "diff", "diagnostics" },
      lualine_c = { "filename" },
      lualine_x = { "encoding", "fileformat", "filetype" },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
  })
end

return M

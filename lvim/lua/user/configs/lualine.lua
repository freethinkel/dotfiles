local M = {}

M.modes = {
  ["n"] = "NORMAL",
  ["no"] = "NORMAL (no)",
  ["nov"] = "NORMAL (nov)",
  ["noV"] = "NORMAL (noV)",
  ["noCTRL-V"] = "NORMAL",
  ["niI"] = "NORMAL i",
  ["niR"] = "NORMAL r",
  ["niV"] = "NORMAL v",
  ["nt"] = "NTERMINAL",
  ["ntT"] = "NTERMINAL (ntT)",

  ["v"] = "VISUAL",
  ["vs"] = "V-CHAR (Ctrl O)",
  ["V"] = "V-LINE",
  ["Vs"] = "V-LINE",
  [""] = "V-BLOCK",

  ["i"] = "INSERT",
  ["ic"] = "INSERT (completion)",
  ["ix"] = "INSERT completion",

  ["t"] = "TERMINAL",

  ["R"] = "REPLACE",
  ["Rc"] = "REPLACE (Rc)",
  ["Rx"] = "REPLACEa (Rx)",
  ["Rv"] = "V-REPLACE",
  ["Rvc"] = "V-REPLACE (Rvc)",
  ["Rvx"] = "V-REPLACE (Rvx)",

  ["s"] = "SELECT",
  ["S"] = "S-LINE",
  [""] = "S-BLOCK",
  ["c"] = "COMMAND",
  ["cv"] = "COMMAND",
  ["ce"] = "COMMAND",
  ["r"] = "PROMPT",
  ["rm"] = "MORE",
  ["r?"] = "CONFIRM",
  ["x"] = "CONFIRM",
  ["!"] = "SHELL",
}

M.setup = function()
  local lualine_components                = require("lvim.core.lualine.components")
  lvim.builtin.lualine.style              = "lvim"
  lvim.builtin.lualine.sections.lualine_a = {
    {
      function()
        return " " .. M.modes[vim.api.nvim_get_mode()["mode"]] .. " "
      end,
      padding = { left = 0, right = 0 },
      color = {},
      cond = nil,
    },
  }
  lvim.builtin.lualine.sections.lualine_b = {
    { "branch", icon = "  " }
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

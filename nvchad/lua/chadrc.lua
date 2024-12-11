-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "snowfall_dark",
  theme_toggle = { "snowfall_dark", "snowfall_light" },

  hl_override = {
    NvDashAscii = {
      bg = "none",
      fg = "green",
    },
    Comment = { italic = true },
    ["@comment"] = { italic = true },
  },
  hl_add = {
    DapUIStopNC = { link = "DapUIStop" },
    DapUIRestartNC = { link = "DapUIRestart" },
    DapUIStepOutNC = { link = "DapUIStepOut" },
    DapUIStepBackNC = { link = "DapUIStepBack" },
    DapUIStepIntoNC = { link = "DapUIStepInto" },
    DapUIStepOverNC = { link = "DapUIStepOver" },
    DapUIPlayPauseNC = { link = "DapUIPlayPause" },
    DapUIUnavailableNC = { link = "DapUIUnavailable" },
  },
}

M.ui = {
  theme = "snowfall_dark",
  theme_toggle = { "snowfall_dark", "snowfall_light" },
  cmp = {
    style = "atom",
  },
}

M.nvdash = {
  load_on_startup = true,
  -- header = {
  --   "        ▓████████████▓        ",
  --   "       ▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓       ",
  --   "       █▒▒▒▒▒▒▒▒▒▒▒▒▒▒█       ",
  --   "       █▒▒▓██▓▒▒▓██▓▒▒█       ",
  --   "       █▒▒▓██▓▒▒▓██▓▒▒█       ",
  --   "       █▒▒▒▒▒▒▒▒▒▒▒▒▒▒█       ",
  --   "       ▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓       ",
  --   "        ▓████████████▓        ",
  -- },
  buttons = {
    { txt = "  Find File", keys = "ff", cmd = "Telescope find_files" },
    { txt = "  Recent Files", keys = "fo", cmd = "Telescope oldfiles" },
    { txt = "󰈭  Find Word", keys = "fw", cmd = "Telescope live_grep" },
    { txt = "󱥚  Themes", keys = "th", cmd = ":lua require('nvchad.themes').open()" },
    { txt = "  Mappings", keys = "ch", cmd = "NvCheatsheet" },
    {
      txt = "  Restore Session",
      keys = "s",
      cmd = ":lua require('persistence').load()",
    },
    { txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },
    {
      txt = function()
        local stats = require("lazy").stats()
        local ms = math.floor(stats.startuptime) .. " ms"
        return "  Loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms
      end,
      hl = "NvDashFooter",
      no_gap = true,
    },

    { txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },
  },
}

return M
